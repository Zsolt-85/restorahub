import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../constants/routes.dart';
import '../helpers/appointment_actions.dart';
import '../l10n/app_localizations.dart';
import '../models/appointment.dart';
import '../pages/booking_page.dart';
import '../providers/appointment_provider.dart';
import '../providers/auth_provider.dart';
import '../providers/service_provider.dart';
import '../widgets/appointment_card.dart';
import '../widgets/appointment_card_skeleton.dart';
import '../widgets/app_drawer.dart';
import '../widgets/empty_state_widget.dart';
import '../widgets/user_profile_avatar.dart';

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
        Navigator.pushNamedAndRemoveUntil(context, Routes.login, (_) => false);
      });
      return const Scaffold(body: SizedBox.shrink());
    }

    final isCustomer = user.role == 'customer';

    return Scaffold(
      appBar: AppBar(
        title: Text(AppLocalizations.of(context)?.dashboard ?? 'Dashboard'),
        actions: const [
          UserProfileAvatar(),
        ],
      ),
      drawer: AppDrawer(user: user, auth: auth),
      body: _buildBody(context, apptProvider, isCustomer),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          if (isCustomer) {
            _bookNow(context);
          } else {
            Navigator.pushNamed(context, Routes.professionalHome);
          }
        },
        tooltip: isCustomer
            ? AppLocalizations.of(context)?.bookNow ?? 'Book appointment'
            : AppLocalizations.of(context)?.professionalContact ??
                'Manage bookings',
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
              const Icon(Icons.wifi_off_rounded,
                  size: 48, color: Colors.redAccent),
              const SizedBox(height: 16),
              Text(
                AppLocalizations.of(context)?.error ??
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
                onPressed: () => apptProvider.loadAppointments(),
                icon: const Icon(Icons.refresh),
                label: Text(AppLocalizations.of(context)?.retry ?? 'Retry'),
              ),
            ],
          ),
        ),
      );
    }

    if (isCustomer) {
      return _buildCustomerDashboardBody(context, apptProvider);
    }

    final appointments = apptProvider.filteredAppointments;
    if (appointments.isEmpty) {
      return EmptyStateWidget(
        icon: Icons.calendar_today_outlined,
        title:
            AppLocalizations.of(context)?.noAppointments ?? 'No Bookings Yet',
        subtitle: AppLocalizations.of(context)?.noAppointments ??
            'Explore local wellness professionals and schedule your next appointment.',
        actionButton: ElevatedButton.icon(
          onPressed: () {
            Navigator.pushNamed(context, Routes.services);
          },
          icon: const Icon(Icons.add),
          label:
              Text(AppLocalizations.of(context)?.bookNow ?? 'Book a Service'),
        ),
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
          onEdit: (appt) => AppointmentActions.confirmReschedule(context, appt),
          onCancel: () => AppointmentActions.confirmCancel(context, appt),
        );
      },
    );
  }

  Widget _buildCustomerDashboardBody(
    BuildContext context,
    AppointmentProvider apptProvider,
  ) {
    return DefaultTabController(
      length: 2,
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: TabBar(
              isScrollable: false,
              indicatorSize: TabBarIndicatorSize.tab,
              indicator: BoxDecoration(
                color: Theme.of(context).colorScheme.primary,
                borderRadius: BorderRadius.circular(8),
              ),
              labelColor: Theme.of(context).colorScheme.onPrimary,
              unselectedLabelColor:
                  Theme.of(context).colorScheme.onSurfaceVariant,
              tabs: [
                Tab(text: AppLocalizations.of(context)?.upcoming ?? 'Upcoming'),
                Tab(text: AppLocalizations.of(context)?.history ?? 'History'),
              ],
            ),
          ),
          const SizedBox(height: 8),
          Expanded(
            child: TabBarView(
              children: [
                _buildAppointmentSection(
                  context,
                  apptProvider.upcomingAppointments,
                  isUpcoming: true,
                  onEdit: (appt) => _navigateToReschedule(context, appt),
                ),
                _buildAppointmentSection(
                  context,
                  apptProvider.pastAppointments,
                  isUpcoming: false,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _navigateToReschedule(BuildContext context, Appointment appt) {
    if (appt.id == null || appt.id!.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            AppLocalizations.of(context)?.error ??
                'Unable to reschedule this appointment',
          ),
        ),
      );
      return;
    }

    String baseService = appt.service;
    if (baseService.contains('\u2014')) {
      baseService = baseService.split('\u2014').first.trim();
    }
    final category = ServiceProvider.getCategoryForService(baseService);

    final auth = Provider.of<AuthProvider>(context, listen: false);
    Navigator.pushNamed(
      context,
      Routes.booking,
      arguments: {
        'service': appt.service,
        'category': category.isEmpty ? null : category,
        'appointmentId': appt.id,
        'businessId': auth.currentUser?.businessId,
      },
    );
  }

  void _bookNow(BuildContext context) {
    final user = Provider.of<AuthProvider>(context, listen: false).currentUser;
    final businessId = user?.businessId;
    if (businessId != null && businessId.isNotEmpty) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => BookingPage(businessId: businessId),
        ),
      );
    } else {
      Navigator.pushNamed(context, Routes.services);
    }
  }

  Widget _buildAppointmentSection(
    BuildContext context,
    List<Appointment> appointments, {
    required bool isUpcoming,
    void Function(Appointment)? onEdit,
  }) {
    final loc = AppLocalizations.of(context);
    if (appointments.isEmpty) {
      final IconData icon;
      final String title;
      final String subtitle;
      final Widget? actionButton;
      if (isUpcoming) {
        icon = Icons.calendar_today_outlined;
        title = loc?.noUpcomingAppointments ?? 'No upcoming appointments';
        subtitle =
            loc?.noUpcomingAppointmentsSubtitle ?? 'Ready for your next visit?';
        actionButton = ElevatedButton(
          onPressed: () => _bookNow(context),
          child: Text(loc?.bookNow ?? 'Book Now'),
        );
      } else {
        icon = Icons.history;
        title = loc?.noAppointmentHistory ?? 'No past appointments';
        subtitle = loc?.noAppointmentHistorySubtitle ??
            'Your completed bookings will show up here.';
        actionButton = null;
      }
      return EmptyStateWidget(
        icon: icon,
        title: title,
        subtitle: subtitle,
        actionButton: actionButton,
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: appointments.length,
      itemBuilder: (context, index) {
        final appt = appointments[index];
        return AppointmentCard(
          appointment: appt,
          viewerIsCustomer: true,
          onEdit: onEdit,
          onCancel: () => AppointmentActions.confirmCancel(context, appt),
        );
      },
    );
  }
}
