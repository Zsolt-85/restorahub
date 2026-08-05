import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';
import 'repositories/firestore_booking_repository.dart';
import 'repositories/notification_repository.dart';
import 'repositories/firestore_payment_repository.dart';
import 'repositories/payment_repository.dart';
import 'helpers/notification_schedule_helper.dart';

import 'models/user.dart';
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
import 'models/booking_summary.dart';
import 'pages/success_page.dart';
import 'pages/user_home_page.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  await NotificationScheduleHelper.initialize();

  final firestoreRepo = FirestoreBookingRepository.instance;
  final notificationRepo = FirestoreNotificationRepository.instance;
  final paymentRepo = FirestorePaymentRepository.instance;
  final authProvider = AuthProvider(repository: firestoreRepo);
  final appointmentProvider = AppointmentProvider(repository: firestoreRepo);
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

  final initialRoute = _resolveInitialRoute(authProvider.currentUser);

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

String _resolveInitialRoute(User? user) {
  if (user == null) return '/login';
  return user.role == 'professional' ? '/professional_home' : '/user_home';
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
            routes: {
              '/login': (_) => const LoginPage(),
              '/register': (_) => const RegistrationPage(),
              '/forgot-password': (_) => const ForgotPasswordPage(),
              '/user_home': (_) => const UserHomePage(),
              '/professional_home': (_) =>
                  const ProfessionalBookingManagementPage(),
              '/success': (context) {
                final summary = ModalRoute.of(context)?.settings.arguments
                    as BookingSummary?;
                return SuccessPage(summary: summary);
              },
              '/profile': (_) => const ProfilePage(),
              '/notifications': (_) => const NotificationsPage(),
              '/analytics': (_) => const AnalyticsPage(),
              '/past_appointments': (_) => const PastAppointmentsPage(),
            },
          );
        },
      ),
    );
  }
}
