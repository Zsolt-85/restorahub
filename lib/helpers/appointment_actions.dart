import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../constants/routes.dart';
import '../exceptions/app_exception.dart';
import '../l10n/app_localizations.dart';
import '../helpers/format_helper.dart';
import '../models/appointment.dart';
import '../providers/appointment_provider.dart';
import '../utils/error_handler.dart';

class AppointmentActions {
  static Future<void> confirmCancel(
    BuildContext context,
    Appointment appointment,
  ) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(AppLocalizations.of(context)?.cancelBooking ?? 'Cancel booking?'),
        content: Text(
          '${AppLocalizations.of(context)?.cancel ?? 'Cancel'} "${appointment.service}" on '
          '${FormatHelper.formatDateTime(appointment.dateTime)}?\n\n${AppLocalizations.of(context)?.confirm ?? 'This cannot be undone.'}',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(AppLocalizations.of(context)?.keepBooking ?? 'Keep booking'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text(
              AppLocalizations.of(context)?.cancelBookingAction ?? 'Cancel booking',
              style: const TextStyle(color: Colors.red),
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
        SnackBar(content: Text(AppLocalizations.of(context)?.bookingCancelled ?? 'Booking cancelled')),
      );
    } on AppException catch (e) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('${AppLocalizations.of(context)?.failedToUpdate ?? 'Failed to update booking'}: ${e.message}')),
      );
    } catch (e) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(AppLocalizations.of(context)?.failedToUpdate ?? 'Failed to update booking')),
      );
    }
  }

  static Future<void> confirmProfessionalCancel(
    BuildContext context,
    Appointment appointment,
  ) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(AppLocalizations.of(context)?.cancelBooking ?? 'Cancel booking?'),
        content: Text(
          '${AppLocalizations.of(context)?.cancel ?? 'Cancel'} "${appointment.service}" on '
          '${FormatHelper.formatDateTime(appointment.dateTime)}?\n\n${AppLocalizations.of(context)?.confirm ?? 'This cannot be undone.'}',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(AppLocalizations.of(context)?.keepBooking ?? 'Keep booking'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text(
              AppLocalizations.of(context)?.cancelBookingAction ?? 'Cancel booking',
              style: const TextStyle(color: Colors.red),
            ),
          ),
        ],
      ),
    );

    if (confirmed != true || !context.mounted) return;

    try {
      final error = await Provider.of<AppointmentProvider>(context, listen: false)
          .professionalCancelAppointment(appointment.id!);

      if (!context.mounted) return;

      if (error != null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('${AppLocalizations.of(context)?.failedToUpdate ?? 'Failed to update booking'}: $error')),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(AppLocalizations.of(context)?.bookingCancelled ?? 'Booking cancelled')),
        );
      }
    } catch (e) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(AppLocalizations.of(context)?.failedToUpdate ?? 'Failed to update booking')),
      );
    }
  }

  static Future<void> confirmReschedule(
    BuildContext context,
    Appointment appointment,
  ) async {
    final updated = await Navigator.pushNamed<bool>(
      context,
      Routes.editAppointment,
      arguments: appointment,
    );

    if (updated == true && context.mounted) {
      try {
        await Provider.of<AppointmentProvider>(context, listen: false)
            .loadAppointments();
      } on AppException catch (e) {
        if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('${AppLocalizations.of(context)?.failedToRefresh ?? 'Failed to refresh bookings'}: ${e.message}')),
      );
      } catch (e) {
        if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(AppLocalizations.of(context)?.failedToRefresh ?? 'Failed to refresh bookings')),
      );
      }
    }
  }

  static Future<void> acceptAppointment(
    BuildContext context,
    Appointment appointment,
  ) async {
    try {
      await Provider.of<AppointmentProvider>(context, listen: false)
          .updateAppointmentStatus(appointment.id!, AppointmentStatus.confirmed);

      if (!context.mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(AppLocalizations.of(context)?.bookingConfirmed ?? 'Booking confirmed')),
      );
    } on AppException catch (e) {
      if (!context.mounted) return;
      ErrorHandler.showErrorSnackBar(context, e);
    } catch (e) {
      if (!context.mounted) return;
      ErrorHandler.showErrorSnackBar(context, e);
    }
  }

  static Future<void> declineAppointment(
    BuildContext context,
    Appointment appointment,
  ) async {
    try {
      await Provider.of<AppointmentProvider>(context, listen: false)
          .updateAppointmentStatus(
            appointment.id!,
            AppointmentStatus.cancelledByProfessional,
          );

      if (!context.mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(AppLocalizations.of(context)?.bookingDeclined ?? 'Booking declined')),
      );
    } on AppException catch (e) {
      if (!context.mounted) return;
      ErrorHandler.showErrorSnackBar(context, e);
    } catch (e) {
      if (!context.mounted) return;
      ErrorHandler.showErrorSnackBar(context, e);
    }
  }

  static Future<void> confirmProfessionalDecision(
    BuildContext context,
    Appointment appointment,
  ) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(AppLocalizations.of(context)?.newBookingRequest ?? 'New booking request'),
        content: Text(
          '${AppLocalizations.of(context)?.accept ?? 'Accept'} "${appointment.service}" from ${appointment.customerName ?? AppLocalizations.of(context)?.customer ?? 'this customer'} on '
          '${FormatHelper.formatDateTime(appointment.dateTime)}?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(
              AppLocalizations.of(context)?.decline ?? 'Decline',
              style: const TextStyle(color: Colors.red),
            ),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text(AppLocalizations.of(context)?.accept ?? 'Accept'),
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

      final label = newStatus == AppointmentStatus.confirmed
          ? AppLocalizations.of(context)?.confirmed ?? 'confirmed'
          : AppLocalizations.of(context)?.decline ?? 'declined';
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('${AppLocalizations.of(context)?.bookingConfirmed ?? 'Booking'} $label')),
      );
    } on AppException catch (e) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to update booking: ${e.message}')),
      );
    } catch (e) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(AppLocalizations.of(context)?.bookingDeclined ?? 'Booking declined')),
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
        actionLabel = AppLocalizations.of(context)?.confirmBookingAction ?? 'Confirm booking';
        confirmMessage = AppLocalizations.of(context)?.confirmThisBooking ?? 'Confirm this booking?';
        break;
      case AppointmentStatus.completed:
        actionLabel = AppLocalizations.of(context)?.markAsCompleted ?? 'Mark as completed';
        confirmMessage = AppLocalizations.of(context)?.markAsCompleted ?? 'Mark this appointment as completed?';
        break;
      case AppointmentStatus.cancelledByCustomer:
        actionLabel = AppLocalizations.of(context)?.cancelBookingAction ?? 'Cancel booking';
        confirmMessage = AppLocalizations.of(context)?.cancelThisBooking ?? 'Cancel this booking?';
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
            child: Text(AppLocalizations.of(context)?.keepAsIs ?? 'Keep as is'),
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

      final label = newStatus.displayLabel;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('${AppLocalizations.of(context)?.bookingConfirmed ?? 'Booking'} $label')),
      );
    } on AppException catch (e) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to update booking: ${e.message}')),
      );
    } catch (e) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(AppLocalizations.of(context)?.bookingDeclined ?? 'Booking declined')),
      );
    }
  }
}
