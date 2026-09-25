import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';

import 'package:restorahub/constants/routes.dart';
import 'package:restorahub/main.dart';
import 'package:restorahub/models/appointment.dart';
import 'package:restorahub/models/business.dart';
import 'package:restorahub/models/notification.dart';
import 'package:restorahub/models/payment.dart';
import 'package:restorahub/models/user.dart';
import 'package:restorahub/pages/add_payment_page.dart';
import 'package:restorahub/pages/admin_calendar_page.dart';
import 'package:restorahub/pages/admin_dashboard_page.dart';
import 'package:restorahub/pages/analytics_dashboard_page.dart';
import 'package:restorahub/pages/analytics_page.dart';
import 'package:restorahub/pages/booking_page.dart';
import 'package:restorahub/pages/business_settings_page.dart';
import 'package:restorahub/pages/earnings_report_page.dart';
import 'package:restorahub/pages/edit_appointment_page.dart';
import 'package:restorahub/pages/forgot_password_page.dart';
import 'package:restorahub/pages/login_page.dart';
import 'package:restorahub/pages/notifications_page.dart';
import 'package:restorahub/pages/past_appointments_page.dart';
import 'package:restorahub/pages/professional_booking_management_page.dart';
import 'package:restorahub/pages/professional_manual_booking_page.dart';
import 'package:restorahub/pages/profile_page.dart';
import 'package:restorahub/pages/receipt_page.dart';
import 'package:restorahub/pages/registration_page.dart';
import 'package:restorahub/pages/services_page.dart';
import 'package:restorahub/pages/settings_page.dart';
import 'package:restorahub/pages/setup_wizard_page.dart';
import 'package:restorahub/pages/success_page.dart';
import 'package:restorahub/pages/super_admin_dashboard_page.dart';
import 'package:restorahub/pages/team_management_page.dart';
import 'package:restorahub/pages/user_home_page.dart';
import 'package:restorahub/providers/auth_provider.dart';
import 'package:restorahub/providers/business_provider.dart';
import 'package:restorahub/providers/notification_provider.dart';
import 'package:restorahub/repositories/notification_repository.dart';
import 'package:restorahub/repositories/user_repository.dart';
import 'package:restorahub/widgets/app_drawer.dart';

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

Appointment _appointment() => Appointment(
      id: 'a1',
      service: 'Massage',
      dateTime: DateTime(2030, 5, 1, 10, 0),
      durationMinutes: 60,
      customerId: 'cust-1',
      professionalId: 'prof-1',
    );

Payment _payment() => Payment(
      appointmentId: 'a1',
      customerId: 'cust-1',
      customerName: 'Customer',
      customerPhone: '555-0100',
      customerEmail: 'cust@test.com',
      professionalId: 'prof-1',
      professionalName: 'Professional',
      professionalPhone: '555-0200',
      professionalEmail: 'prof@test.com',
      service: 'Massage',
      staffCategory: 'massage',
      appointmentDate: DateTime(2030, 5, 1, 10, 0),
      appointmentTime: '10:00',
      appointmentDurationMinutes: 60,
      amount: 50.0,
    );

Future<BuildContext> _testContext(WidgetTester tester) async {
  await tester.pumpWidget(const MaterialApp(home: Scaffold(body: Text('ctx'))));
  return tester.element(find.text('ctx'));
}

void main() {
  group('Route table (buildRouteWidget)', () {
    testWidgets('every static route resolves to its page', (tester) async {
      final context = await _testContext(tester);
      final cases = <String, Type>{
        Routes.login: LoginPage,
        Routes.register: RegistrationPage,
        Routes.forgotPassword: ForgotPasswordPage,
        Routes.customerHome: UserHomePage,
        Routes.professionalHome: ProfessionalBookingManagementPage,
        Routes.professionalManualBooking: ProfessionalManualBookingPage,
        Routes.services: ServicesPage,
        Routes.profile: ProfilePage,
        Routes.notifications: NotificationsPage,
        Routes.analytics: AnalyticsPage,
        Routes.pastAppointments: PastAppointmentsPage,
        Routes.settings: SettingsPage,
        Routes.teamManagement: TeamManagementPage,
        Routes.adminCalendar: AdminCalendarPage,
        Routes.superAdminDashboard: SuperAdminDashboardPage,
        Routes.setupWizard: SetupWizardPage,
        Routes.adminDashboard: AdminDashboardPage,
        Routes.analyticsDashboard: AnalyticsDashboardPage,
        Routes.businessSettings: BusinessSettingsPage,
        Routes.earningsReport: EarningsReportPage,
        Routes.success: SuccessPage,
      };
      for (final entry in cases.entries) {
        final widget = buildRouteWidget(
            context, entry.key, RouteSettings(name: entry.key));
        expect(widget.runtimeType, entry.value,
            reason: 'route ${entry.key} should build ${entry.value}');
      }
    });

    testWidgets('booking route handles all argument shapes', (tester) async {
      final context = await _testContext(tester);
      expect(
          buildRouteWidget(context, Routes.booking,
              const RouteSettings(name: Routes.booking)),
          isA<BookingPage>());
      expect(
          buildRouteWidget(context, Routes.booking,
              const RouteSettings(name: Routes.booking, arguments: 'Massage')),
          isA<BookingPage>());
      final mapWidget = buildRouteWidget(
          context,
          Routes.booking,
          const RouteSettings(name: Routes.booking, arguments: {
            'service': 'Massage',
            'category': 'massage',
            'appointmentId': 'a1',
            'businessId': 'b1',
          }));
      expect(mapWidget, isA<BookingPage>());
      expect((mapWidget as BookingPage).businessId, 'b1');
    });

    testWidgets('parameterized routes resolve with valid arguments',
        (tester) async {
      final context = await _testContext(tester);
      expect(
          buildRouteWidget(
              context,
              Routes.editAppointment,
              RouteSettings(
                  name: Routes.editAppointment, arguments: _appointment())),
          isA<EditAppointmentPage>());
      expect(
          buildRouteWidget(
              context,
              Routes.addPayment,
              RouteSettings(
                  name: Routes.addPayment, arguments: _appointment())),
          isA<AddPaymentPage>());
      expect(
          buildRouteWidget(context, Routes.receipt,
              RouteSettings(name: Routes.receipt, arguments: _payment())),
          isA<ReceiptPage>());
    });

    testWidgets('parameterized routes handle missing arguments safely',
        (tester) async {
      final context = await _testContext(tester);
      // editAppointment degrades to an error scaffold instead of throwing.
      expect(
          buildRouteWidget(context, Routes.editAppointment,
              const RouteSettings(name: Routes.editAppointment)),
          isA<Scaffold>());
      // addPayment/receipt require arguments and must fail loudly, never blank.
      expect(
          () => buildRouteWidget(context, Routes.addPayment,
              const RouteSettings(name: Routes.addPayment)),
          throwsA(anything));
      expect(
          () => buildRouteWidget(context, Routes.receipt,
              const RouteSettings(name: Routes.receipt)),
          throwsA(anything));
    });

    testWidgets('completeProfile renders inline scaffold', (tester) async {
      final context = await _testContext(tester);
      expect(
          buildRouteWidget(context, Routes.completeProfile,
              const RouteSettings(name: Routes.completeProfile)),
          isA<Scaffold>());
    });

    testWidgets('completeProfile explains the sign-in detour', (tester) async {
      final context = await _testContext(tester);
      final widget = buildRouteWidget(context, Routes.completeProfile,
          const RouteSettings(name: Routes.completeProfile));

      await tester.pumpWidget(MaterialApp(home: widget));

      expect(find.textContaining('Sign in to finish'), findsOneWidget);
      expect(find.text('Continue to sign in'), findsOneWidget);
    });

    testWidgets('unknown route falls back to login', (tester) async {
      final context = await _testContext(tester);
      expect(
          buildRouteWidget(context, '/no-such-route',
              const RouteSettings(name: '/no-such-route')),
          isA<LoginPage>());
    });
  });

  group('Drawer navigation smoke test', () {
    testWidgets('Business Settings tile opens /business_settings',
        (tester) async {
      final auth = AuthProvider(userRepository: FakeUserRepository());
      auth.currentUser = User(
        id: 'admin-1',
        name: 'Admin',
        email: 'admin@test.com',
        phone: '555-0000',
        role: 'business_admin',
        businessId: 'b1',
      );
      final businessProvider = BusinessProvider()
        ..setBusiness(Business(
            id: 'b1', name: 'Test Biz', status: BusinessStatus.active));
      final notifications =
          NotificationProvider(repository: FakeNotificationRepository());

      await tester.pumpWidget(
        MultiProvider(
          providers: [
            ChangeNotifierProvider<AuthProvider>.value(value: auth),
            ChangeNotifierProvider<BusinessProvider>.value(
                value: businessProvider),
            ChangeNotifierProvider<NotificationProvider>.value(
                value: notifications),
          ],
          child: MaterialApp(
            routes: {
              Routes.businessSettings: (_) =>
                  const Scaffold(body: Text('settings-dest')),
            },
            home: Builder(
              builder: (context) => Scaffold(
                drawer: AppDrawer(user: auth.currentUser!, auth: auth),
                body: const Text('home'),
              ),
            ),
          ),
        ),
      );

      tester.state<ScaffoldState>(find.byType(Scaffold).first).openDrawer();
      await tester.pumpAndSettle();
      await tester.tap(find.text('Business Settings'));
      await tester.pumpAndSettle();
      expect(find.text('settings-dest'), findsOneWidget);
    });
  });
}
