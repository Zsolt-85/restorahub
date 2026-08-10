import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../helpers/appointment_actions.dart';
import '../models/appointment.dart';
import '../models/user.dart';
import '../providers/appointment_provider.dart';
import '../providers/auth_provider.dart';
import '../widgets/appointment_card.dart';
import '../widgets/appointment_card_skeleton.dart';
import '../widgets/app_drawer.dart';
import '../widgets/empty_state_widget.dart';
import '../widgets/professional_calendar_view.dart';
import '../widgets/user_profile_avatar.dart';

class ProfessionalBookingManagementPage extends StatefulWidget {
  const ProfessionalBookingManagementPage({super.key});

  @override
  State<ProfessionalBookingManagementPage> createState() =>
      _ProfessionalBookingManagementPageState();
}

class _ProfessionalBookingManagementPageState
    extends State<ProfessionalBookingManagementPage>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
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
    _tabController.dispose();
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

    return Scaffold(
      appBar: AppBar(
        title: const Text('Manage bookings'),
        actions: [
          const UserProfileAvatar(),
        ],
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: 'Upcoming'),
            Tab(text: 'Past'),
            Tab(text: 'Calendar'),
          ],
        ),
      ),
      drawer: AppDrawer(user: user, auth: auth),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildUpcoming(context, apptProvider),
          _buildPast(context, apptProvider),
          _buildCalendar(context, apptProvider, user),
        ],
      ),
    );
  }

  Widget _buildUpcoming(BuildContext context, AppointmentProvider apptProvider) {
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

    final appointments = apptProvider.upcomingAppointments;
    if (appointments.isEmpty) {
      return const EmptyStateWidget(
        icon: Icons.event_available,
        title: 'No upcoming bookings',
        subtitle: 'New bookings from customers will appear here',
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

  Widget _buildPast(BuildContext context, AppointmentProvider apptProvider) {
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

    final appointments = apptProvider.pastAppointments;
    if (appointments.isEmpty) {
      return const EmptyStateWidget(
        icon: Icons.history,
        title: 'No past bookings',
        subtitle: 'Completed and cancelled bookings will appear here',
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: appointments.length,
      itemBuilder: (context, index) {
        final appt = appointments[index];
        return AppointmentCard(
          appointment: appt,
          viewerIsCustomer: false,
          onEdit: () {},
          onCancel: () {},
        );
      },
    );
  }

  Widget _buildCalendar(BuildContext context, AppointmentProvider apptProvider, User user) {
    return ProfessionalCalendarView(professional: user);
  }
}
