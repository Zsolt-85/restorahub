import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../l10n/app_localizations.dart';
import '../providers/appointment_provider.dart';
import '../providers/auth_provider.dart';
import '../widgets/appointment_card.dart';
import '../widgets/empty_state_widget.dart';

class PastAppointmentsPage extends StatefulWidget {
  const PastAppointmentsPage({super.key});

  @override
  State<PastAppointmentsPage> createState() => _PastAppointmentsPageState();
}

class _PastAppointmentsPageState extends State<PastAppointmentsPage> {
  @override
  Widget build(BuildContext context) {
    final auth = Provider.of<AuthProvider>(context);
    final apptProvider = Provider.of<AppointmentProvider>(context);
    final user = auth.currentUser;

    if (user == null) {
      return const Scaffold(body: SizedBox.shrink());
    }

    final pastAppointments = apptProvider.pastAppointments;

    return Scaffold(
      appBar: AppBar(
        title: Text(AppLocalizations.of(context)?.pastAppointments ?? 'Past appointments'),
      ),
      body: pastAppointments.isEmpty
          ? EmptyStateWidget(
              icon: Icons.history,
              title: AppLocalizations.of(context)?.noAppointments ?? 'No past appointments',
              subtitle: AppLocalizations.of(context)?.history ??
                  'Completed and cancelled appointments will appear here',
            )
          : ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: pastAppointments.length,
              itemBuilder: (context, index) {
                final appt = pastAppointments[index];
                return AppointmentCard(
                  appointment: appt,
                  viewerIsCustomer: user.role == 'customer',
                  onEdit: () {},
                  onCancel: () {},
                );
              },
            ),
    );
  }
}