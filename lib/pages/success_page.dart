import 'package:flutter/material.dart';

import '../helpers/format_helper.dart';
import '../models/booking_summary.dart';

class SuccessPage extends StatelessWidget {
  const SuccessPage({super.key, this.summary});

  final BookingSummary? summary;

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
              const SizedBox(height: 28),
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
