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

  static Future<void> openReschedule(
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
}
