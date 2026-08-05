import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../helpers/calendar_helper.dart';
import '../helpers/format_helper.dart';
import '../models/booking_summary.dart';
import '../providers/appointment_provider.dart';
import '../providers/auth_provider.dart';

class SuccessPage extends StatelessWidget {
  const SuccessPage({super.key, this.summary});

  final BookingSummary? summary;

  Future<void> _addToCalendar(BuildContext context) async {
    if (summary == null) return;

    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final apptProvider = Provider.of<AppointmentProvider>(context, listen: false);

    final professional = summary!.professionalId != null
        ? await apptProvider.repository.getUserById(summary!.professionalId!)
        : null;

    if (professional == null) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Unable to add to calendar: professional not found')),
      );
      return;
    }

    final appointment = summary!.toAppointment(
      customerId: authProvider.currentUser?.id,
    );

    try {
      await CalendarHelper.addToNativeCalendar(appointment, professional);
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Added to calendar')),
      );
    } on CalendarException catch (e) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to add to calendar: ${e.message}')),
      );
    } catch (e) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Failed to add to calendar')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Icon(Icons.check_circle, size: 88, color: Colors.green),
              const SizedBox(height: 20),
              Text(
                'Booking confirmed!',
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.headlineSmall,
              ),
              const SizedBox(height: 24),
              if (summary != null)
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _SummaryRow(
                          icon: Icons.spa_outlined,
                          label: 'Service',
                          value: summary!.service,
                        ),
                        const SizedBox(height: 12),
                        _SummaryRow(
                          icon: Icons.person_outline,
                          label: 'Professional',
                          value: summary!.professionalName,
                        ),
                        const SizedBox(height: 12),
                        _SummaryRow(
                          icon: Icons.event,
                          label: 'When',
                          value: FormatHelper.formatDateTime(summary!.dateTime),
                        ),
                        const SizedBox(height: 12),
                        _SummaryRow(
                          icon: Icons.timelapse,
                          label: 'Duration',
                          value: '${summary!.durationMinutes} minutes',
                        ),
                      ],
                    ),
                  ),
                ),
              const SizedBox(height: 16),
              if (summary != null)
                ElevatedButton.icon(
                  onPressed: () => _addToCalendar(context),
                  icon: const Icon(Icons.calendar_today),
                  label: const Text('Add to Calendar'),
                ),
              const SizedBox(height: 12),
              ElevatedButton(
                onPressed: () {
                  Navigator.pushNamedAndRemoveUntil(
                    context,
                    '/user_home',
                    (route) => false,
                  );
                },
                child: const Text('Back to dashboard'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SummaryRow extends StatelessWidget {
  const _SummaryRow({
    required this.icon,
    required this.label,
    required this.value,
  });

  final IconData icon;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 20),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: Theme.of(context).textTheme.bodySmall,
              ),
              Text(
                value,
                style: Theme.of(context).textTheme.bodyLarge,
              ),
            ],
          ),
        ),
      ],
    );
  }
}
