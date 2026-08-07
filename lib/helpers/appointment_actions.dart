import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../helpers/app_exception.dart';
import '../models/appointment.dart';
import '../pages/edit_appointment_page.dart';
import '../providers/appointment_provider.dart';

class AppointmentActions {
  static Future<void> confirmCancel(
    BuildContext context,
    Appointment appointment,
  ) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Cancel booking?'),
        content: Text(
          'Cancel "${appointment.service}" on '
          '${appointment.dateTime.toLocal()}?\n\nThis cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Keep booking'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text(
              'Cancel booking',
              style: TextStyle(color: Colors.red),
            ),
          ),
        ],
      ),
    );

    if (confirmed != true || !context.mounted) return;

    try {
      await Provider.of<AppointmentProvider>(context, listen: false)
          .cancelAppointment(appointment.id!);

      if (!context.mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Booking cancelled')),
      );
    } on AppException catch (e) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to cancel booking: ${e.message}')),
      );
    } catch (e) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Failed to cancel booking')),
      );
    }
  }

  static Future<void> confirmReschedule(
    BuildContext context,
    Appointment appointment,
  ) async {
    final updated = await Navigator.push<bool>(
      context,
      MaterialPageRoute(
        builder: (_) => EditAppointmentPage(appointment: appointment),
      ),
    );

    if (updated == true && context.mounted) {
      try {
        await Provider.of<AppointmentProvider>(context, listen: false)
            .loadAppointments();
      } on AppException catch (e) {
        if (!context.mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to refresh bookings: ${e.message}')),
        );
      } catch (e) {
        if (!context.mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Failed to refresh bookings')),
        );
      }
    }
  }

  static Future<void> confirmProfessionalDecision(
    BuildContext context,
    Appointment appointment,
  ) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('New booking request'),
        content: Text(
          'Accept "${appointment.service}" from ${appointment.customerName ?? 'this customer'} on '
          '${appointment.dateTime.toLocal()}?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text(
              'Decline',
              style: TextStyle(color: Colors.red),
            ),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Accept'),
          ),
        ],
      ),
    );

    if (confirmed == null || !context.mounted) return;

    try {
      final newStatus = confirmed
          ? AppointmentStatus.confirmed
          : AppointmentStatus.cancelledByProfessional;
      await Provider.of<AppointmentProvider>(context, listen: false)
          .updateAppointmentStatus(appointment.id!, newStatus);

      if (!context.mounted) return;

      final label = newStatus == AppointmentStatus.confirmed ? 'confirmed' : 'declined';
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Booking $label')),
      );
    } on AppException catch (e) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to update booking: ${e.message}')),
      );
    } catch (e) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Failed to update booking')),
      );
    }
  }

  static Future<void> confirmStatusChange(
    BuildContext context,
    Appointment appointment,
    AppointmentStatus newStatus,
  ) async {
    final String actionLabel;
    final String confirmMessage;

    switch (newStatus) {
      case AppointmentStatus.confirmed:
        actionLabel = 'Confirm booking';
        confirmMessage = 'Confirm this booking?';
        break;
      case AppointmentStatus.completed:
        actionLabel = 'Mark as completed';
        confirmMessage = 'Mark this appointment as completed?';
        break;
      case AppointmentStatus.cancelledByCustomer:
        actionLabel = 'Cancel booking';
        confirmMessage = 'Cancel this booking?';
        break;
      default:
        return;
    }

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(actionLabel),
        content: Text(confirmMessage),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Keep as is'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text(
              actionLabel,
              style: TextStyle(
                 color: newStatus == AppointmentStatus.cancelledByCustomer
                    ? Colors.red
                    : null,
              ),
            ),
          ),
        ],
      ),
    );

    if (confirmed != true || !context.mounted) return;

    try {
      await Provider.of<AppointmentProvider>(context, listen: false)
          .updateAppointmentStatus(appointment.id!, newStatus);

      if (!context.mounted) return;

      final label = newStatus.name.toUpperCase();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Booking $label')),
      );
    } on AppException catch (e) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to update booking: ${e.message}')),
      );
    } catch (e) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Failed to update booking')),
      );
    }
  }
}
