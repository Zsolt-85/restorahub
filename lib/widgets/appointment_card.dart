import 'package:flutter/material.dart';

import '../helpers/format_helper.dart';
import '../helpers/appointment_actions.dart';
import '../models/appointment.dart';

class AppointmentCard extends StatelessWidget {
  const AppointmentCard({
    super.key,
    required this.appointment,
    required this.viewerIsCustomer,
    required this.onEdit,
    required this.onCancel,
    this.onConfirm,
    this.onReject,
  });

  final Appointment appointment;
  final bool viewerIsCustomer;
  final VoidCallback onEdit;
  final VoidCallback onCancel;
  final VoidCallback? onConfirm;
  final VoidCallback? onReject;

  @override
  Widget build(BuildContext context) {
    final counterpartyName = viewerIsCustomer
        ? appointment.professionalName
        : appointment.customerName;
    final counterpartyPhone = viewerIsCustomer
        ? appointment.professionalPhone
        : appointment.customerPhone;
    final counterpartyEmail = viewerIsCustomer
        ? appointment.professionalEmail
        : appointment.customerEmail;
    final counterpartyLabel =
        viewerIsCustomer ? 'Professional' : 'Customer';
    final statusColor = _statusColor(appointment.status);
    final canManage = viewerIsCustomer == false &&
        appointment.status != AppointmentStatus.completed &&
        !appointment.isCancelled &&
        !appointment.isPast;

    final showCustomerRemove = viewerIsCustomer &&
        appointment.status == AppointmentStatus.pending &&
        !appointment.isPast;

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                CircleAvatar(
                  child: Icon(
                    viewerIsCustomer ? Icons.spa_outlined : Icons.person,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        appointment.service,
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(FormatHelper.formatDateTime(appointment.dateTime)),
                      Text('Duration: ${appointment.durationMinutes} min'),
                      const SizedBox(height: 4),
                       Text(
                         appointment.status.displayLabel,
                         style: TextStyle(
                           color: statusColor,
                           fontWeight: FontWeight.w600,
                           fontSize: 12,
                         ),
                       ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Text(
              '$counterpartyLabel contact',
              style: Theme.of(context).textTheme.titleSmall,
            ),
            const SizedBox(height: 8),
            _ContactRow(
              icon: Icons.person_outline,
              label: 'Name',
              value: counterpartyName ?? 'N/A',
            ),
            _ContactRow(
              icon: Icons.phone_outlined,
              label: 'Phone',
              value: _displayValue(counterpartyPhone),
            ),
            _ContactRow(
              icon: Icons.email_outlined,
              label: 'Email',
              value: _displayValue(counterpartyEmail),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                if (!viewerIsCustomer && appointment.status == AppointmentStatus.pending) ...[
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: onReject,
                      icon: const Icon(Icons.cancel_outlined, color: Colors.red),
                      label: const Text(
                        'Reject',
                        style: TextStyle(color: Colors.red),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: onConfirm,
                      icon: const Icon(Icons.check_circle),
                      label: const Text('Confirm'),
                    ),
                  ),
                ] else if (canManage) ...[
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: appointment.isPast ? null : onEdit,
                      icon: const Icon(Icons.edit_calendar),
                      label: const Text('Reschedule'),
                    ),
                  ),
                  const SizedBox(width: 12),
                ],
                if (canManage &&
                    (!viewerIsCustomer || appointment.status == AppointmentStatus.pending)) ...[
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: onCancel,
                      icon: const Icon(Icons.cancel_outlined, color: Colors.red),
                      label: const Text(
                        'Cancel',
                        style: TextStyle(color: Colors.red),
                      ),
                    ),
                  ),
                ],
                if (showCustomerRemove) ...[
                  const SizedBox(width: 12),
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () => AppointmentActions.confirmStatusChange(
                        context,
                        appointment,
                        AppointmentStatus.cancelledByCustomer,
                      ),
                      icon: const Icon(Icons.delete_outline, color: Colors.red),
                      label: const Text(
                        'Remove',
                        style: TextStyle(color: Colors.red),
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ],
        ),
      ),
    );
  }

  String _displayValue(String? value) {
    if (value == null || value.trim().isEmpty) return 'N/A';
    return value;
  }
}

Color _statusColor(AppointmentStatus status) {
  switch (status) {
    case AppointmentStatus.pending:
      return Colors.orange;
    case AppointmentStatus.confirmed:
      return Colors.green;
    case AppointmentStatus.completed:
      return Colors.blue;
    case AppointmentStatus.cancelledByCustomer:
    case AppointmentStatus.cancelledByProfessional:
      return Colors.red;
    case AppointmentStatus.noShow:
      return Colors.grey;
  }
}

class _ContactRow extends StatelessWidget {
  const _ContactRow({
    required this.icon,
    required this.label,
    required this.value,
  });

  final IconData icon;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 18),
          const SizedBox(width: 8),
          Expanded(
            child: RichText(
              text: TextSpan(
                style: Theme.of(context).textTheme.bodyMedium,
                children: [
                  TextSpan(
                    text: '$label: ',
                    style: const TextStyle(fontWeight: FontWeight.w600),
                  ),
                  TextSpan(text: value),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
