import 'package:flutter/material.dart';

import '../helpers/app_exception.dart';
import '../helpers/notification_schedule_helper.dart';
import '../models/appointment.dart';
import '../models/user.dart';
import '../repositories/booking_repository.dart';
import '../repositories/firestore_booking_repository.dart';

class AppointmentProvider extends ChangeNotifier {
  AppointmentProvider({BookingRepository? repository})
      : _repository = repository ?? FirestoreBookingRepository.instance;

  final BookingRepository _repository;

  BookingRepository get repository => _repository;

  List<Appointment> _appointments = [];
  User? currentUser;

  List<Appointment> get appointments => _appointments;

  bool _isLoading = false;
  String? _error;

  bool get isLoading => _isLoading;
  String? get error => _error;

  void _beginLoading() {
    _isLoading = true;
    _error = null;
    notifyListeners();
  }

  void _endLoading([String? error]) {
    _isLoading = false;
    _error = error;
    notifyListeners();
  }

  Future<void> loadAppointments() async {
    _beginLoading();
    try {
      await _reloadAppointments();
      _endLoading();
    } on AppException catch (e) {
      _endLoading(e.message);
    } catch (e) {
      _endLoading('Unexpected error loading appointments');
    }
  }

  Future<void> _reloadAppointments() async {
    if (currentUser == null) return;
    final userId = currentUser!.id;
    if (userId == null) return;
    if (currentUser!.role == 'customer') {
      _appointments = await _repository.getAppointmentsForCustomer(userId);
    } else if (currentUser!.isProfessional) {
      _appointments = await _repository.getAppointmentsForProfessional(userId);
    }
  }

  Future<void> addAppointment(Appointment appt) async {
    _beginLoading();
    try {
      if (appt.professionalId != null) {
        final available = await isSlotAvailable(
          slotStart: appt.dateTime,
          slotDuration: appt.durationMinutes,
          professionalId: appt.professionalId!,
        );
        if (!available) {
          _endLoading('This time slot is no longer available');
          return;
        }
      }
      await _repository.insertAppointment(appt);
      await _reloadAppointments();
      _endLoading();
    } on AppException catch (e) {
      _endLoading(e.message);
    } catch (e) {
      _endLoading('Unexpected error creating booking');
    }
  }

  Future<void> updateAppointment(Appointment appt) async {
    _beginLoading();
    try {
      await _repository.updateAppointment(appt);
      await _reloadAppointments();
      _endLoading();
    } on AppException catch (e) {
      _endLoading(e.message);
    } catch (e) {
      _endLoading('Unexpected error updating booking');
    }
  }

  Future<void> deleteAppointment(String id) async {
    _beginLoading();
    try {
      await _repository.deleteAppointment(id);
      await _reloadAppointments();
      _endLoading();
    } on AppException catch (e) {
      _endLoading(e.message);
    } catch (e) {
      _endLoading('Unexpected error cancelling booking');
    }
  }

  Future<void> updateAppointmentStatus(
    String id,
    AppointmentStatus newStatus,
  ) async {
    _beginLoading();
    try {
      final appt = _appointments.firstWhere((a) => a.id == id);
      final updated = appt.copyWith(status: newStatus);
      await _repository.updateAppointment(updated);
      await _reloadAppointments();
      _endLoading();
    } on AppException catch (e) {
      _endLoading(e.message);
    } catch (e) {
      _endLoading('Unexpected error updating appointment status');
    }
  }

  List<Appointment> get pendingAppointments {
    return _appointments
        .where((a) => a.status == AppointmentStatus.pending)
        .toList();
  }

  List<Appointment> get confirmedAppointments {
    return _appointments
        .where((a) => a.status == AppointmentStatus.confirmed)
        .toList();
  }

  List<Appointment> get completedAppointments {
    return _appointments
        .where((a) => a.status == AppointmentStatus.completed)
        .toList();
  }

  List<Appointment> get cancelledAppointments {
    return _appointments
        .where((a) => a.status == AppointmentStatus.cancelled)
        .toList();
  }

  List<Appointment> get pastAppointments {
    final now = DateTime.now();
    return _appointments
        .where(
          (a) =>
              a.dateTime.isBefore(now) &&
              a.status != AppointmentStatus.pending &&
              a.status != AppointmentStatus.confirmed,
        )
        .toList();
  }

  List<Appointment> get currentAppointments {
    final now = DateTime.now();
    return _appointments
        .where(
          (a) =>
              a.dateTime.isAfter(now) &&
              a.status != AppointmentStatus.cancelled,
        )
        .toList();
  }

  int getAppointmentCountForMonth(int year, int month) {
    final start = DateTime(year, month, 1);
    final end = DateTime(year, month + 1, 1);
    return _appointments
        .where(
          (a) =>
              a.dateTime.isAfter(start) &&
              a.dateTime.isBefore(end),
        )
        .length;
  }

  int getYearToDateAppointmentCount(int year) {
    final start = DateTime(year);
    final now = DateTime.now();
    return _appointments
        .where(
          (a) =>
              a.dateTime.isAfter(start) &&
              a.dateTime.isBefore(now.add(const Duration(days: 1))),
        )
        .length;
  }

  void setCurrentUser(User user) {
    currentUser = user;
    loadAppointments();
  }

  Future<bool> isSlotAvailable({
    required DateTime slotStart,
    required int slotDuration,
    required String professionalId,
  }) async {
    try {
      return await _repository.checkProfessionalAvailability(
        professionalId: professionalId,
        dateTime: slotStart,
        slotDurationMinutes: slotDuration,
      );
    } catch (e) {
      return false;
    }
  }

  Future<void> linkPaymentToAppointment(
    String appointmentId,
    String paymentId,
  ) async {
    _beginLoading();
    try {
      final apptIndex = _appointments.indexWhere((a) => a.id == appointmentId);
      if (apptIndex != -1) {
        final updated = _appointments[apptIndex].copyWith(
          paymentId: paymentId,
          status: AppointmentStatus.completed,
        );
        await _repository.updateAppointment(updated);
        await _reloadAppointments();
      }
      _endLoading();
    } on AppException catch (e) {
      _endLoading(e.message);
    } catch (e) {
      _endLoading('Unexpected error linking payment to appointment');
    }
  }

  Future<String?> cancelAppointment(String id) async {
    await deleteAppointment(id);
    return null;
  }

  Future<String?> rescheduleAppointment({
    required Appointment appointment,
    required DateTime newDateTime,
  }) async {
    if (appointment.professionalId == null) {
      return 'Professional not found for this booking';
    }

    final available = await isSlotAvailable(
      slotStart: newDateTime,
      slotDuration: appointment.durationMinutes,
      professionalId: appointment.professionalId!,
    );

    if (!available) {
      return 'This time slot is no longer available';
    }

    final updated = appointment.copyWith(dateTime: newDateTime);
    await updateAppointment(updated);
    return null;
  }

  List<Appointment> get filteredAppointments {
    if (currentUser == null) return [];

    if (currentUser!.role == 'customer') {
      return _appointments
          .where((a) => a.customerId == currentUser!.id)
          .toList();
    }

    if (currentUser!.isProfessional) {
      return _appointments
          .where((a) => a.professionalId == currentUser!.id)
          .toList();
    }

    return _appointments;
  }

  Future<void> scheduleUpcomingReminders() async {
    final now = DateTime.now();
    for (final appt in _appointments) {
      if (appt.status == AppointmentStatus.cancelled) continue;
      final reminderTime = appt.dateTime.subtract(const Duration(hours: 1));
      if (reminderTime.isAfter(now) && reminderTime.isBefore(appt.dateTime)) {
        try {
          await NotificationScheduleHelper.scheduleUpcomingReminder(
            appointmentId: appt.id ?? '',
            title: 'Appointment reminder',
            body: '${appt.service} with ${appt.professionalName ?? "a professional"} is in 1 hour',
            scheduledTime: reminderTime,
          );
        } catch (e) {
          debugPrint('Failed to schedule reminder: $e');
        }
      }
    }
  }
}
