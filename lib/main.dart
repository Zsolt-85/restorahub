import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';
import 'repositories/firestore_booking_repository.dart';
import 'repositories/firestore_user_repository.dart';
import 'repositories/user_repository.dart';
import 'repositories/notification_repository.dart';
import 'repositories/firestore_payment_repository.dart';
import 'repositories/payment_repository.dart';
import 'helpers/notification_schedule_helper.dart';
import 'helpers/route_guard_helper.dart';
import 'constants/routes.dart';

import 'models/booking_summary.dart';
import 'providers/appointment_provider.dart';
import 'providers/auth_provider.dart';
import 'providers/notification_provider.dart';
import 'providers/theme_provider.dart';
import 'providers/payment_provider.dart';

import 'pages/analytics_page.dart';
import 'pages/forgot_password_page.dart';
import 'pages/login_page.dart';
import 'pages/notifications_page.dart';
import 'pages/past_appointments_page.dart';
import 'pages/profile_page.dart';
import 'pages/professional_booking_management_page.dart';
import 'pages/registration_page.dart';
import 'pages/success_page.dart';
import 'pages/user_home_page.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  await NotificationScheduleHelper.initialize();

  final bookingRepo = FirestoreBookingRepository.instance;
  final userRepo = FirestoreUserRepository.instance;
  final notificationRepo = FirestoreNotificationRepository.instance;
  final paymentRepo = FirestorePaymentRepository.instance;
  final authProvider = AuthProvider(userRepository: userRepo);
  final appointmentProvider = AppointmentProvider(
    bookingRepository: bookingRepo,
    userRepository: userRepo,
    notificationRepository: notificationRepo,
  );
  final themeProvider = ThemeProvider();

  await themeProvider.loadTheme();
  await appointmentProvider.loadAppointments();

  if (appointmentProvider.error != null) {
    debugPrint('Warning: initial appointments load failed: ${appointmentProvider.error}');
  }

  final hasSession = await authProvider.restoreSession();
  if (hasSession && authProvider.currentUser != null) {
    appointmentProvider.setCurrentUser(authProvider.currentUser!);
  }

  final initialRoute = _resolveInitialRoute(authProvider);

  runApp(
    MyApp(
      authProvider: authProvider,
      appointmentProvider: appointmentProvider,
      themeProvider: themeProvider,
      initialRoute: initialRoute,
      notificationRepo: notificationRepo,
      paymentRepo: paymentRepo,
    ),
  );
}

String _resolveInitialRoute(AuthProvider authProvider) {
  return RouteGuardHelper.evaluateRedirect(
    currentRoute: Routes.login,
    authProvider: authProvider,
  ) ?? Routes.login;
}

class MyApp extends StatelessWidget {
  const MyApp({
    super.key,
    required this.authProvider,
    required this.appointmentProvider,
    required this.themeProvider,
    required this.initialRoute,
    required this.notificationRepo,
    required this.paymentRepo,
  });

  final AuthProvider authProvider;
  final AppointmentProvider appointmentProvider;
  final ThemeProvider themeProvider;
  final String initialRoute;
  final NotificationRepository notificationRepo;
  final PaymentRepository paymentRepo;

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider<AuthProvider>.value(value: authProvider),
        ChangeNotifierProvider<AppointmentProvider>.value(
          value: appointmentProvider,
        ),
        Provider<UserRepository>.value(value: FirestoreUserRepository.instance),
        ChangeNotifierProvider<ThemeProvider>.value(value: themeProvider),
        Provider<NotificationRepository>.value(value: notificationRepo),
        ChangeNotifierProxyProvider<NotificationRepository, NotificationProvider>(
          create: (context) => NotificationProvider(
            repository: context.read<NotificationRepository>(),
          ),
          update: (context, repo, provider) {
            if (provider == null) {
              return NotificationProvider(repository: repo);
            }
            return provider;
          },
        ),
        Provider<PaymentRepository>.value(value: paymentRepo),
        ChangeNotifierProxyProvider<PaymentRepository, PaymentProvider>(
          create: (context) => PaymentProvider(
            repository: context.read<PaymentRepository>(),
          ),
          update: (context, repo, provider) {
            if (provider == null) {
              return PaymentProvider(repository: repo);
            }
            return provider;
          },
        ),
      ],
      child: Consumer<ThemeProvider>(
        builder: (context, theme, _) {
          return MaterialApp(
            debugShowCheckedModeBanner: false,
            title: 'RestoraHub',
            theme: theme.theme,
            initialRoute: initialRoute,
            onGenerateRoute: (settings) {
              final route = settings.name ?? Routes.login;
              final redirect = RouteGuardHelper.evaluateRedirect(
                currentRoute: route,
                authProvider: authProvider,
              );

              final targetRoute = redirect ?? route;

              return MaterialPageRoute(
                builder: (context) {
                  switch (targetRoute) {
                    case Routes.login:
                      return const LoginPage();
                    case Routes.register:
                      return const RegistrationPage();
                    case Routes.customerHome:
                      return const UserHomePage();
                    case Routes.professionalHome:
                      return const ProfessionalBookingManagementPage();
                    case '/forgot-password':
                      return const ForgotPasswordPage();
                    case Routes.completeProfile:
                      return Scaffold(
                        appBar: AppBar(title: const Text('Complete Profile')),
                        body: Center(
                          child: Padding(
                            padding: const EdgeInsets.all(24),
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                const Text(
                                  'Your profile is incomplete.',
                                  style: TextStyle(fontSize: 18),
                                ),
                                const SizedBox(height: 16),
                                ElevatedButton(
                                  onPressed: () => Navigator.pushNamedAndRemoveUntil(
                                    context,
                                    Routes.login,
                                    (_) => false,
                                  ),
                                  child: const Text('Go to Login'),
                                ),
                              ],
                            ),
                          ),
                        ),
                      );
                    case '/success':
                      final summary = settings.arguments as BookingSummary?;
                      return SuccessPage(summary: summary);
                    case '/profile':
                      return const ProfilePage();
                    case '/notifications':
                      return const NotificationsPage();
                    case '/analytics':
                      return const AnalyticsPage();
                    case '/past_appointments':
                      return const PastAppointmentsPage();
                    default:
                      return const LoginPage();
                  }
                },
              );
            },
            onUnknownRoute: (_) =>
                MaterialPageRoute(builder: (_) => const LoginPage()),
          );
        },
      ),
    );
  }
}
