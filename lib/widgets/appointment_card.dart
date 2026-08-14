import 'package:flutter/material.dart';

import '../helpers/format_helper.dart';
import '../helpers/appointment_actions.dart';
import '../l10n/app_localizations.dart';
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
        viewerIsCustomer
            ? AppLocalizations.of(context)?.counterpartyProfessional ?? 'Professional'
            : AppLocalizations.of(context)?.counterpartyCustomer ?? 'Customer';
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
                      Text('${AppLocalizations.of(context)?.duration ?? 'Duration'}: ${appointment.durationMinutes} ${AppLocalizations.of(context)?.mins ?? 'min'}'),
                      const SizedBox(height: 4),
                        Text(
                          _localizedStatus(context, appointment.status),
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
              AppLocalizations.of(context)?.professionalContact ?? '$counterpartyLabel contact',
              style: Theme.of(context).textTheme.titleSmall,
            ),
            const SizedBox(height: 8),
            _ContactRow(
              icon: Icons.person_outline,
              label: AppLocalizations.of(context)?.name ?? 'Name',
              value: counterpartyName ?? AppLocalizations.of(context)?.notSetValue ?? 'N/A',
            ),
            _ContactRow(
              icon: Icons.phone_outlined,
              label: AppLocalizations.of(context)?.phone ?? 'Phone',
              value: _displayValue(counterpartyPhone, context),
            ),
            _ContactRow(
              icon: Icons.email_outlined,
              label: AppLocalizations.of(context)?.email ?? 'Email',
              value: _displayValue(counterpartyEmail, context),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                if (!viewerIsCustomer && appointment.status == AppointmentStatus.pending) ...[
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: onReject,
                      icon: const Icon(Icons.cancel_outlined, color: Colors.red),
                      label: Text(
                        AppLocalizations.of(context)?.decline ?? 'Decline',
                        style: TextStyle(color: Colors.red),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: onConfirm,
                      icon: const Icon(Icons.check_circle),
                      label: Text(AppLocalizations.of(context)?.accept ?? 'Accept'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: appointment.isPast ? null : onEdit,
                      icon: const Icon(Icons.edit_calendar),
                      label: Text(AppLocalizations.of(context)?.reschedule ?? 'Reschedule'),
                    ),
                  ),
                ] else if (canManage) ...[
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: appointment.isPast ? null : onEdit,
                      icon: const Icon(Icons.edit_calendar),
                      label: Text(AppLocalizations.of(context)?.reschedule ?? 'Reschedule'),
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
                      label: Text(
                        AppLocalizations.of(context)?.cancel ?? 'Cancel',
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
                      label: Text(
                        AppLocalizations.of(context)?.delete ?? 'Remove',
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

  String _displayValue(String? value, BuildContext context) {
    if (value == null || value.trim().isEmpty) return AppLocalizations.of(context)?.notSetValue ?? 'N/A';
    return value;
  }

  String _localizedStatus(BuildContext context, AppointmentStatus status) {
    final l10n = AppLocalizations.of(context);
    switch (status) {
      case AppointmentStatus.pending:
        return l10n?.statusPending ?? 'Pending';
      case AppointmentStatus.confirmed:
        return l10n?.statusConfirmed ?? 'Confirmed';
      case AppointmentStatus.completed:
        return l10n?.statusCompleted ?? 'Completed';
      case AppointmentStatus.cancelledByCustomer:
      case AppointmentStatus.cancelledByProfessional:
        return l10n?.statusCancelled ?? 'Cancelled';
      case AppointmentStatus.noShow:
        return 'No Show';
    }
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
