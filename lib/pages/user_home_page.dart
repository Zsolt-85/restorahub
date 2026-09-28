import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../constants/routes.dart';
import '../config/photo_catalog.dart';
import '../widgets/premium/brand_image.dart';
import '../widgets/premium/entrance.dart';
import '../helpers/appointment_actions.dart';
import '../helpers/format_helper.dart';
import '../l10n/app_localizations.dart';
import '../models/appointment.dart';
import '../pages/booking_page.dart';
import '../providers/appointment_provider.dart';
import '../providers/auth_provider.dart';
import '../providers/service_provider.dart';
import '../widgets/appointment_card.dart';
import '../widgets/appointment_card_skeleton.dart';
import '../widgets/app_drawer.dart';
import '../widgets/premium/branded_empty_state.dart';
import '../widgets/user_profile_avatar.dart';

String greetingForHour(int hour) {
  if (hour < 12) return 'Good morning';
  if (hour < 18) return 'Good afternoon';
  return 'Good evening';
}

/// Localized greeting mirroring [greetingForHour]'s day-part branching.
/// Kept as a separate helper so the pure [greetingForHour] (and its unit
/// test) stays untouched; call sites use this for customer-visible copy.
String localizedGreetingForHour(BuildContext context, int hour) {
  final l10n = AppLocalizations.of(context);
  if (hour < 12) return l10n?.greetingMorning ?? 'Good morning';
  if (hour < 18) return l10n?.greetingAfternoon ?? 'Good afternoon';
  return l10n?.greetingEvening ?? 'Good evening';
}

String firstName(String name) {
  final token = name.trim().split(RegExp(r'\s+')).firstWhere(
        (p) => p.isNotEmpty,
        orElse: () => '',
      );
  return token;
}

class UserHomePage extends StatefulWidget {
  const UserHomePage({super.key, this.showChrome = true});

  final bool showChrome;

  @override
  State<UserHomePage> createState() => _UserHomePageState();
}

class _UserHomePageState extends State<UserHomePage> {
  AppointmentProvider? _appointmentProvider;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final auth = Provider.of<AuthProvider>(context, listen: false);
      final apptProvider =
          Provider.of<AppointmentProvider>(context, listen: false);
      _appointmentProvider = apptProvider;
      if (auth.currentUser != null) {
        apptProvider.setCurrentUser(auth.currentUser!);
        apptProvider.startRealtimeAppointments();
      }
    });
  }

  @override
  void dispose() {
    _appointmentProvider?.stopRealtimeAppointments();
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
      appBar: widget.showChrome
          ? AppBar(
              title:
                  Text(AppLocalizations.of(context)?.dashboard ?? 'Dashboard'),
              actions: const [
                UserProfileAvatar(),
              ],
            )
          : null,
      drawer:
          widget.showChrome ? AppDrawer(user: user, auth: auth) : null,
      body: _buildBody(context, apptProvider, isCustomer),
      floatingActionButton: widget.showChrome
          ? FloatingActionButton(
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
            )
          : null,
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
                AppLocalizations.of(context)?.appointmentsLoadFail ??
                    "We couldn't load your visits — check connection and retry.",
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
      return BrandedEmptyState(
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
        return Entrance(
          index: index,
          child: AppointmentCard(
            appointment: appt,
            viewerIsCustomer: isCustomer,
            onEdit: (appt) =>
                AppointmentActions.confirmReschedule(context, appt),
            onCancel: () => AppointmentActions.confirmCancel(context, appt),
          ),
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
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 4),
            child: Align(
              alignment: Alignment.centerLeft,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    localizedGreetingForHour(context, DateTime.now().hour),
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: Theme.of(context).colorScheme.onSurfaceVariant,
                        ),
                  ),
                  Text(
                    firstName(Provider.of<AuthProvider>(context, listen: false)
                            .currentUser
                            ?.name ??
                        ''),
                    style: Theme.of(context).textTheme.displaySmall,
                  ),
                ],
              ),
            ),
          ),
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
            AppLocalizations.of(context)?.rescheduleOpenFail ??
                "We couldn't open rescheduling — try again.",
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
        title = loc?.emptyUpcomingTitle ?? 'No upcoming visits';
        subtitle =
            loc?.emptyUpcomingSubtitle ?? 'Ready for your next visit?';
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
      return BrandedEmptyState(
        icon: icon,
        title: title,
        subtitle: subtitle,
        actionButton: actionButton,
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: appointments.length + (isUpcoming ? 1 : 0),
      itemBuilder: (context, index) {
        if (index == 0 && isUpcoming) {
          return Entrance(
            index: 0,
            child: _buildNextHero(context, appointments.first),
          );
        }
        final appt = appointments[isUpcoming ? index - 1 : index];
        return Entrance(
          index: index,
          child: AppointmentCard(
            appointment: appt,
            viewerIsCustomer: true,
            onEdit: onEdit,
            onCancel: () => AppointmentActions.confirmCancel(context, appt),
          ),
        );
      },
    );
  }

  Widget _buildNextHero(BuildContext context, Appointment appt) {
    final scheme = Theme.of(context).colorScheme;
    final text = Theme.of(context).textTheme;
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: scheme.inverseSurface,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          BrandImage(
            catalogKey: heroImage(),
            imageUrl: null,
            fallbackLabel: appt.service,
            height: 140,
            borderRadius: 20,
          ),
          const SizedBox(height: 12),
          Text(
            AppLocalizations.of(context)?.nextAppointment ??
                'Next appointment',
            style: text.labelSmall?.copyWith(
              color: scheme.inversePrimary,
              letterSpacing: 1.2,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            appt.service,
            style: text.titleLarge?.copyWith(color: scheme.onInverseSurface),
          ),
          const SizedBox(height: 4),
          Text(
            '${FormatHelper.formatDateTime(appt.dateTime)} · ${appt.professionalName ?? ''}',
            style: text.bodyMedium?.copyWith(color: scheme.onInverseSurface),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: FilledButton(
                  onPressed: () => _navigateToReschedule(context, appt),
                  child: const Text('Reschedule'),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: OutlinedButton(
                  onPressed: () =>
                      AppointmentActions.confirmCancel(context, appt),
                  child: const Text('Cancel'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
