import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

import 'helpers/database_helper.dart';
import 'models/user.dart';
import 'providers/appointment_provider.dart';
import 'providers/auth_provider.dart';
import 'providers/theme_provider.dart';

import 'pages/login_page.dart';
import 'pages/profile_page.dart';
import 'pages/professional_booking_management_page.dart';
import 'pages/registration_page.dart';
import 'models/booking_summary.dart';
import 'pages/success_page.dart';
import 'pages/user_home_page.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  sqfliteFfiInit();
  databaseFactory = databaseFactoryFfi;

  await DatabaseHelper.instance.database;

  final authProvider = AuthProvider();
  final appointmentProvider = AppointmentProvider();
  final themeProvider = ThemeProvider();

  await themeProvider.loadTheme();
  await appointmentProvider.loadAppointments();

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
  });

  final AuthProvider authProvider;
  final AppointmentProvider appointmentProvider;
  final ThemeProvider themeProvider;
  final String initialRoute;

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider<AuthProvider>.value(value: authProvider),
        ChangeNotifierProvider<AppointmentProvider>.value(
          value: appointmentProvider,
        ),
        ChangeNotifierProvider<ThemeProvider>.value(value: themeProvider),
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
              '/user_home': (_) => const UserHomePage(),
              '/professional_home': (_) =>
                  const ProfessionalBookingManagementPage(),
              '/success': (context) {
                final summary = ModalRoute.of(context)?.settings.arguments
                    as BookingSummary?;
                return SuccessPage(summary: summary);
              },
              '/profile': (_) => const ProfilePage(),
            },
          );
        },
      ),
    );
  }
}
