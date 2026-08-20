import 'package:flutter/material.dart';

import '../helpers/format_helper.dart';
import '../helpers/appointment_actions.dart';
import '../helpers/calendar_export_helper.dart';
import '../l10n/app_localizations.dart';
import '../models/appointment.dart';

class AppointmentCard extends StatelessWidget {
  const AppointmentCard({
    super.key,
    required this.appointment,
    required this.viewerIsCustomer,
    this.onEdit,
    required this.onCancel,
    this.onConfirm,
    this.onReject,
  });

  final Appointment appointment;
  final bool viewerIsCustomer;
  final void Function(Appointment)? onEdit;
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

    final canAddToCalendar = !appointment.isPast && !appointment.isTerminal;

    final actionButtons = <Widget>[
      if (!viewerIsCustomer && appointment.status == AppointmentStatus.pending) ...[
        OutlinedButton.icon(
          onPressed: onReject,
          icon: const Icon(Icons.cancel_outlined, color: Colors.red),
          label: FittedBox(
            fit: BoxFit.scaleDown,
            child: Text(
              AppLocalizations.of(context)?.decline ?? 'Decline',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(color: Colors.red),
            ),
          ),
        ),
        ElevatedButton.icon(
          onPressed: onConfirm,
          icon: const Icon(Icons.check_circle),
          label: FittedBox(
            fit: BoxFit.scaleDown,
            child: Text(
              AppLocalizations.of(context)?.accept ?? 'Accept',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ),
        OutlinedButton.icon(
          onPressed: appointment.isPast ? null : (onEdit != null ? () => onEdit!(appointment) : null),
          icon: const Icon(Icons.edit_calendar),
          label: FittedBox(
            fit: BoxFit.scaleDown,
            child: Text(
              AppLocalizations.of(context)?.reschedule ?? 'Reschedule',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ),
      ] else if (canManage) ...[
        OutlinedButton.icon(
          onPressed: appointment.isPast ? null : (onEdit != null ? () => onEdit!(appointment) : null),
          icon: const Icon(Icons.edit_calendar),
          label: FittedBox(
            fit: BoxFit.scaleDown,
            child: Text(
              AppLocalizations.of(context)?.reschedule ?? 'Reschedule',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ),
      ],
      if (viewerIsCustomer &&
          !appointment.isPast &&
          !appointment.isTerminal &&
          onEdit != null) ...[
        OutlinedButton.icon(
          onPressed: () => onEdit!(appointment),
          icon: const Icon(Icons.edit_calendar),
          label: FittedBox(
            fit: BoxFit.scaleDown,
            child: Text(
              AppLocalizations.of(context)?.reschedule ?? 'Reschedule',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ),
      ],
      if (canManage &&
          (!viewerIsCustomer || appointment.status == AppointmentStatus.pending)) ...[
        OutlinedButton.icon(
          onPressed: onCancel,
          icon: const Icon(Icons.cancel_outlined, color: Colors.red),
          label: FittedBox(
            fit: BoxFit.scaleDown,
            child: Text(
              AppLocalizations.of(context)?.cancel ?? 'Cancel',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(color: Colors.red),
            ),
          ),
        ),
      ],
      if (showCustomerRemove) ...[
        OutlinedButton.icon(
          onPressed: () => AppointmentActions.confirmStatusChange(
            context,
            appointment,
            AppointmentStatus.cancelledByCustomer,
          ),
          icon: const Icon(Icons.delete_outline, color: Colors.red),
          label: FittedBox(
            fit: BoxFit.scaleDown,
            child: Text(
              AppLocalizations.of(context)?.delete ?? 'Remove',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(color: Colors.red),
            ),
          ),
        ),
      ],
    ];

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
                      if (appointment.price != null) ...[
                        const SizedBox(height: 4),
                        Text(
                          '${AppLocalizations.of(context)?.price ?? 'Price'}: ${FormatHelper.formatCurrency(appointment.price!)}',
                          style: TextStyle(
                            fontWeight: FontWeight.w600,
                            fontSize: 13,
                            color: Theme.of(context).colorScheme.primary,
                          ),
                        ),
                      ],
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
            if (actionButtons.isNotEmpty) ...[
              _buildActionButtonRow(actionButtons),
            ],
            if (canAddToCalendar) ...[
              const SizedBox(height: 8),
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: () => _showCalendarOptions(context),
                  icon: const Icon(Icons.calendar_today),
                  label: Text(
                    AppLocalizations.of(context)?.addToCalendar ?? 'Add to Calendar',
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildActionButtonRow(List<Widget> buttons) {
    if (buttons.isEmpty) return const SizedBox.shrink();
    if (buttons.length == 1) {
      return Row(children: [Expanded(child: buttons.first)]);
    }
    if (buttons.length == 2) {
      return Row(
        children: [
          Expanded(child: buttons[0]),
          const SizedBox(width: 8),
          Expanded(child: buttons[1]),
        ],
      );
    }
    final firstRow = buttons.take(2).toList();
    final secondRow = buttons.skip(2).toList();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            Expanded(child: firstRow[0]),
            const SizedBox(width: 8),
            Expanded(child: firstRow[1]),
          ],
        ),
        if (secondRow.isNotEmpty) ...[
          const SizedBox(height: 8),
          if (secondRow.length == 1)
            Row(children: [Expanded(child: secondRow.first)])
          else
            Row(
              children: [
                Expanded(child: secondRow[0]),
                const SizedBox(width: 8),
                Expanded(child: secondRow[1]),
              ],
            ),
        ],
      ],
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

  void _showCalendarOptions(BuildContext context) {
    showModalBottomSheet(
      context: context,
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.calendar_today),
              title: Text(
                AppLocalizations.of(context)?.googleCalendar ?? 'Google Calendar',
              ),
              onTap: () async {
                Navigator.pop(context);
                await addToGoogleCalendar(appointment);
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(
                        AppLocalizations.of(context)?.calendarAddedSuccess ??
                            'Calendar event added successfully',
                      ),
                    ),
                  );
                }
              },
            ),
            ListTile(
              leading: const Icon(Icons.phone_iphone),
              title: Text(
                AppLocalizations.of(context)?.appleCalendar ?? 'Apple / Device Calendar',
              ),
              onTap: () async {
                Navigator.pop(context);
                await exportCalendarIcs(appointment);
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(
                        AppLocalizations.of(context)?.calendarAddedSuccess ??
                            'Calendar event added successfully',
                      ),
                    ),
                  );
                }
              },
            ),
          ],
        ),
      ),
    );
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
