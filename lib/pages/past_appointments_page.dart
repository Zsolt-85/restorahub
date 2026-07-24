import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../providers/appointment_provider.dart';
import '../providers/auth_provider.dart';
import '../widgets/appointment_card.dart';

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
        title: const Text('Past appointments'),
      ),
      body: pastAppointments.isEmpty
          ? const Center(
              child: Padding(
                padding: EdgeInsets.all(32),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.history, size: 64, color: Colors.grey),
                    SizedBox(height: 16),
                    Text(
                      'No past appointments',
                      style: TextStyle(fontSize: 18),
                    ),
                  ],
                ),
              ),
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