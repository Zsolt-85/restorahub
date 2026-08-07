import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../helpers/appointment_actions.dart';
import '../models/appointment.dart';
import '../providers/appointment_provider.dart';
import '../providers/auth_provider.dart';
import '../widgets/appointment_card.dart';
import '../widgets/app_drawer.dart';
import 'settings_page.dart';

class ProfessionalBookingManagementPage extends StatefulWidget {
  const ProfessionalBookingManagementPage({super.key});

  @override
  State<ProfessionalBookingManagementPage> createState() =>
      _ProfessionalBookingManagementPageState();
}

class _ProfessionalBookingManagementPageState
    extends State<ProfessionalBookingManagementPage> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final auth = Provider.of<AuthProvider>(context, listen: false);
      final apptProvider =
          Provider.of<AppointmentProvider>(context, listen: false);
      if (auth.currentUser != null) {
        apptProvider.setCurrentUser(auth.currentUser!);
      }
    });
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

    return Scaffold(
      appBar: AppBar(
        title: const Text('Manage bookings'),
        actions: [
          IconButton(
            icon: const Icon(Icons.settings_outlined),
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const SettingsPage()),
            ),
          ),
        ],
      ),
      drawer: AppDrawer(user: user, auth: auth),
      body: _buildBody(context, apptProvider),
    );
  }

  Widget _buildBody(BuildContext context, AppointmentProvider apptProvider) {
    if (apptProvider.isLoading) {
      return const Center(child: CircularProgressIndicator());
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
                'Could not load bookings',
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: 8),
              Text(
                apptProvider.error!,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              ElevatedButton.icon(
                onPressed: () => apptProvider.loadAppointments(),
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
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.event_available,
                size: 56,
                color: Theme.of(context).colorScheme.primary,
              ),
              const SizedBox(height: 16),
              Text(
                'No bookings yet',
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: 8),
              const Text(
                'Customer bookings assigned to you will appear here',
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: appointments.length,
      itemBuilder: (context, index) {
        final appt = appointments[index];
        final isPending = appt.status == AppointmentStatus.pending;
        return AppointmentCard(
          appointment: appt,
          viewerIsCustomer: false,
          onEdit: () => AppointmentActions.confirmReschedule(context, appt),
          onCancel: () => AppointmentActions.confirmCancel(context, appt),
          onConfirm: isPending
              ? () => AppointmentActions.confirmProfessionalDecision(context, appt)
              : null,
          onReject: isPending
              ? () => AppointmentActions.confirmProfessionalDecision(context, appt)
              : null,
        );
      },
    );
  }
}
