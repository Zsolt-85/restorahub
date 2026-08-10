import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../helpers/appointment_actions.dart';
import '../providers/appointment_provider.dart';
import '../providers/auth_provider.dart';
import '../widgets/appointment_card.dart';
import '../widgets/appointment_card_skeleton.dart';
import '../widgets/app_drawer.dart';
import '../widgets/empty_state_widget.dart';
import '../widgets/user_profile_avatar.dart';
import 'professional_booking_management_page.dart';
import 'services_page.dart';

class UserHomePage extends StatefulWidget {
  const UserHomePage({super.key});

  @override
  State<UserHomePage> createState() => _UserHomePageState();
}

class _UserHomePageState extends State<UserHomePage> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final auth = Provider.of<AuthProvider>(context, listen: false);
      final apptProvider =
          Provider.of<AppointmentProvider>(context, listen: false);
      if (auth.currentUser != null) {
        apptProvider.setCurrentUser(auth.currentUser!);
        apptProvider.startRealtimeAppointments();
      }
    });
  }

  @override
  void dispose() {
    Provider.of<AppointmentProvider>(context, listen: false)
        .stopRealtimeAppointments();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final auth = Provider.of<AuthProvider>(context);
    final apptProvider = Provider.of<AppointmentProvider>(context);
    final user = auth.currentUser;

    if (user == null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        Navigator.pushNamedAndRemoveUntil(context, '/login', (_) => false);
      });
      return const Scaffold(body: SizedBox.shrink());
    }

    final isCustomer = user.role == 'customer';

    return Scaffold(
      appBar: AppBar(
        title: const Text('Dashboard'),
        actions: [
          const UserProfileAvatar(),
        ],
      ),
      drawer: AppDrawer(user: user, auth: auth),
      body: _buildBody(context, apptProvider, isCustomer),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          if (isCustomer) {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const ServicesPage()),
            );
          } else {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => const ProfessionalBookingManagementPage(),
              ),
            );
          }
        },
        tooltip: isCustomer ? 'Book appointment' : 'Manage bookings',
        child: Icon(isCustomer ? Icons.add : Icons.manage_accounts),
      ),
    );
  }

  Widget _buildBody(
      BuildContext context,
      AppointmentProvider apptProvider,
      bool isCustomer,
      ) {
    if (apptProvider.isLoading) {
      return ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: 3,
        itemBuilder: (context, index) => const AppointmentCardSkeleton(),
      );
    }

    if (apptProvider.error != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.wifi_off_rounded, size: 48, color: Colors.redAccent),
              const SizedBox(height: 16),
              Text(
                'Could not load appointments',
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: 8),
              Text(
                apptProvider.error!,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              ElevatedButton.icon(
                onPressed: () =>
                    apptProvider.loadAppointments(),
                icon: const Icon(Icons.refresh),
                label: const Text('Retry'),
              ),
            ],
          ),
        ),
      );
    }

    final appointments = apptProvider.filteredAppointments;
    if (appointments.isEmpty) {
      return EmptyStateWidget(
        icon: isCustomer ? Icons.event_busy : Icons.event_busy,
        title: isCustomer ? 'No appointments yet' : 'No bookings yet',
        subtitle: isCustomer
            ? 'Tap + to book your first service'
            : 'Bookings from customers will appear here',
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: appointments.length,
      itemBuilder: (context, index) {
        final appt = appointments[index];
        return AppointmentCard(
          appointment: appt,
          viewerIsCustomer: isCustomer,
          onEdit: () => AppointmentActions.confirmReschedule(context, appt),
          onCancel: () => AppointmentActions.confirmCancel(context, appt),
        );
      },
    );
  }
}
