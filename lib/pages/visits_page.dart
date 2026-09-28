import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../constants/routes.dart';
import '../helpers/appointment_actions.dart';
import '../l10n/app_localizations.dart';
import '../providers/appointment_provider.dart';
import '../widgets/appointment_card.dart';
import '../widgets/premium/branded_empty_state.dart';

class VisitsPage extends StatelessWidget {
  const VisitsPage({super.key});

  @override
  Widget build(BuildContext context) {
    final upcoming =
        Provider.of<AppointmentProvider>(context).upcomingAppointments;
    if (upcoming.isEmpty) {
      return BrandedEmptyState(
        icon: Icons.calendar_today_outlined,
        title: AppLocalizations.of(context)?.emptyUpcomingTitle ??
            'No upcoming visits',
        subtitle: AppLocalizations.of(context)?.emptyUpcomingSubtitle ??
            'Ready for your next visit?',
        actionButton: ElevatedButton(
          onPressed: () => Navigator.pushNamed(context, Routes.booking),
          child: const Text('Book now'),
        ),
      );
    }
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: upcoming.length + 1,
      itemBuilder: (context, index) {
        if (index == upcoming.length) {
          return TextButton(
            onPressed: () =>
                Navigator.pushNamed(context, Routes.pastAppointments),
            child: const Text('View history'),
          );
        }
        final appt = upcoming[index];
        return AppointmentCard(
          appointment: appt,
          viewerIsCustomer: true,
          onCancel: () => AppointmentActions.confirmCancel(context, appt),
        );
      },
    );
  }
}
