import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../exceptions/app_exception.dart';
import '../l10n/app_localizations.dart';
import '../helpers/format_helper.dart';
import '../helpers/schedule_helper.dart';
import '../models/appointment.dart';
import '../models/payment.dart';
import '../providers/appointment_provider.dart';
import '../providers/business_provider.dart';
import '../providers/payment_provider.dart';
import '../utils/error_handler.dart';
import '../pages/edit_appointment_page.dart';

class AppointmentActions {
  /// Shared cancel-confirmation dialog behind [confirmCancel] and
  /// [confirmProfessionalCancel] (previously duplicated verbatim).
  static Future<bool?> _confirmCancelDialog(
    BuildContext context,
    Appointment appointment,
  ) {
    return showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(
            AppLocalizations.of(context)?.cancelBooking ?? 'Cancel booking?'),
        content: Text(
          '${AppLocalizations.of(context)?.cancel ?? 'Cancel'} "${appointment.service}" on '
          '${FormatHelper.formatDateTime(appointment.dateTime)}?\n\n${AppLocalizations.of(context)?.confirm ?? 'This cannot be undone.'}',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(
                AppLocalizations.of(context)?.keepBooking ?? 'Keep booking'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text(
              AppLocalizations.of(context)?.cancelBookingAction ??
                  'Cancel booking',
              style: const TextStyle(color: Colors.red),
            ),
          ),
        ],
      ),
    );
  }

  static Future<void> confirmCancel(
    BuildContext context,
    Appointment appointment,
  ) async {
    final confirmed = await _confirmCancelDialog(context, appointment);

    if (confirmed != true || !context.mounted) return;

    try {
      await Provider.of<AppointmentProvider>(context, listen: false)
          .cancelAppointment(appointment.id!);

      if (!context.mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
            content: Text(AppLocalizations.of(context)?.bookingCancelled ??
                'Booking cancelled')),
      );
    } on AppException catch (e) {
      if (!context.mounted) return;
      ErrorHandler.showErrorSnackBar(context, e);
    } catch (e) {
      if (!context.mounted) return;
      ErrorHandler.showErrorSnackBar(context, e);
    }
  }

  static Future<void> confirmProfessionalCancel(
    BuildContext context,
    Appointment appointment,
  ) async {
    final confirmed = await _confirmCancelDialog(context, appointment);

    if (confirmed != true || !context.mounted) return;

    try {
      final error =
          await Provider.of<AppointmentProvider>(context, listen: false)
              .professionalCancelAppointment(appointment.id!);

      if (!context.mounted) return;

      if (error != null) {
        ErrorHandler.showErrorSnackBar(context, error);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text(AppLocalizations.of(context)?.bookingCancelled ??
                  'Booking cancelled')),
        );
      }
    } catch (e) {
      if (!context.mounted) return;
      ErrorHandler.showErrorSnackBar(context, e);
    }
  }

  static Future<void> confirmReschedule(
    BuildContext context,
    Appointment appointment,
  ) async {
    if (!context.mounted) return;
    if (Navigator.canPop(context)) {
      Navigator.pop(context);
    }
    final updated = await Navigator.of(context, rootNavigator: true).push<bool>(
      MaterialPageRoute<bool>(
        builder: (context) => EditAppointmentPage(appointment: appointment),
        settings: const RouteSettings(name: '/edit-appointment'),
      ),
    );

    if (updated == true && context.mounted) {
      try {
        await Provider.of<AppointmentProvider>(context, listen: false)
            .loadAppointments();
      } on AppException catch (e) {
        if (!context.mounted) return;
        ErrorHandler.showErrorSnackBar(context, e);
      } catch (e) {
        if (!context.mounted) return;
        ErrorHandler.showErrorSnackBar(context, e);
      }
    }
  }

  static Future<void> acceptAppointment(
    BuildContext context,
    Appointment appointment,
  ) async {
    try {
      await Provider.of<AppointmentProvider>(context, listen: false)
          .updateAppointmentStatus(
              appointment.id!, AppointmentStatus.confirmed);

      if (!context.mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
            content: Text(AppLocalizations.of(context)?.bookingConfirmed ??
                'Booking confirmed')),
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
        SnackBar(
            content: Text(AppLocalizations.of(context)?.bookingDeclined ??
                'Booking declined')),
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
        title: Text(AppLocalizations.of(context)?.newBookingRequest ??
            'New booking request'),
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
        SnackBar(
            content: Text(
                '${AppLocalizations.of(context)?.bookingConfirmed ?? 'Booking'} $label')),
      );
    } on AppException catch (e) {
      if (!context.mounted) return;
      ErrorHandler.showErrorSnackBar(context, e);
    } catch (e) {
      if (!context.mounted) return;
      ErrorHandler.showErrorSnackBar(context, e);
    }
  }

  /// Marks the appointment as no-show and, when the business configured
  /// a no-show fee, records it as a pending payment for later collection.
  static Future<void> markNoShow(
    BuildContext context,
    Appointment appointment,
  ) async {
    if (appointment.id == null || appointment.id!.isEmpty) return;
    final appointmentProvider =
        Provider.of<AppointmentProvider>(context, listen: false);
    final error = await appointmentProvider.markNoShow(appointment.id!);
    if (!context.mounted) return;
    if (error != null) {
      ErrorHandler.showErrorSnackBar(context, error);
      return;
    }

    final businessProvider =
        Provider.of<BusinessProvider>(context, listen: false);
    final fee = businessProvider.currentBusiness?.settings?.effectiveNoShowFee ??
        0.0;
    if (fee > 0) {
      try {
        final paymentProvider =
            Provider.of<PaymentProvider>(context, listen: false);
        await paymentProvider.recordPayment(Payment(
          appointmentId: appointment.id!,
          customerId: appointment.customerId ?? '',
          customerName: appointment.customerName ?? 'Unknown',
          customerPhone: appointment.customerPhone ?? '',
          customerEmail: appointment.customerEmail ?? '',
          professionalId: appointment.professionalId ?? '',
          professionalName: appointment.professionalName ?? 'Unknown',
          professionalPhone: appointment.professionalPhone ?? '',
          professionalEmail: appointment.professionalEmail ?? '',
          service: appointment.service,
          staffCategory:
              ScheduleHelper.parseServiceCategory(appointment.service),
          businessId: appointment.businessId,
          appointmentDate: appointment.dateTime,
          appointmentTime:
              '${appointment.dateTime.hour.toString().padLeft(2, '0')}:${appointment.dateTime.minute.toString().padLeft(2, '0')}',
          appointmentDurationMinutes: appointment.durationMinutes,
          amount: fee,
          noShowFee: fee,
          status: PaymentStatus.pending,
        ));
      } catch (e) {
        if (!context.mounted) return;
        ErrorHandler.showErrorSnackBar(context, e);
        return;
      }
    }

    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
          content: Text(AppLocalizations.of(context)?.markedNoShow ??
              'Marked as no-show')),
    );
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
        actionLabel = AppLocalizations.of(context)?.confirmBookingAction ??
            'Confirm booking';
        confirmMessage = AppLocalizations.of(context)?.confirmThisBooking ??
            'Confirm this booking?';
        break;
      case AppointmentStatus.completed:
        actionLabel = AppLocalizations.of(context)?.markAsCompleted ??
            'Mark as completed';
        confirmMessage = AppLocalizations.of(context)?.markAsCompleted ??
            'Mark this appointment as completed?';
        break;
      case AppointmentStatus.cancelledByCustomer:
        final policyWindow = Provider.of<BusinessProvider>(context,
                listen: false)
            .currentBusiness
            ?.settings
            ?.effectiveCancellationWindow;
        if (!appointment.canBeCancelledByCustomer(
            cancellationWindow:
                policyWindow ?? const Duration(hours: 2))) {
          if (!context.mounted) return;
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                AppLocalizations.of(context)?.failedToUpdate ??
                    'Failed to update booking',
              ),
            ),
          );
          return;
        }
        actionLabel = AppLocalizations.of(context)?.cancelBookingAction ??
            'Cancel booking';
        confirmMessage = AppLocalizations.of(context)?.cancelThisBooking ??
            'Cancel this booking?';
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

      final l10n = AppLocalizations.of(context);
      String message;
      switch (newStatus) {
        case AppointmentStatus.confirmed:
          message = l10n?.bookingConfirmed ?? 'Booking confirmed';
          break;
        case AppointmentStatus.completed:
          message =
              '${l10n?.bookingConfirmed ?? 'Booking'} ${l10n?.completedLabel ?? 'Completed'}';
          break;
        case AppointmentStatus.cancelledByCustomer:
          message = l10n?.bookingCancelled ?? 'Booking cancelled';
          break;
        default:
          message = l10n?.bookingConfirmed ?? 'Booking confirmed';
      }
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(message)),
      );
    } on AppException catch (e) {
      if (!context.mounted) return;
      ErrorHandler.showErrorSnackBar(context, e);
    } catch (e) {
      if (!context.mounted) return;
      ErrorHandler.showErrorSnackBar(context, e);
    }
  }
}
