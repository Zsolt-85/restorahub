import 'package:flutter/material.dart';

import '../helpers/app_exception.dart';
import '../helpers/schedule_helper.dart';
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
      _appointments = await _repository.getAppointments();
      _endLoading();
    } on AppException catch (e) {
      _endLoading(e.message);
    } catch (e) {
      _endLoading('Unexpected error loading appointments');
    }
  }

  Future<void> addAppointment(Appointment appt) async {
    _beginLoading();
    try {
      await _repository.insertAppointment(appt);
      _appointments = await _repository.getAppointments();
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
      _appointments = await _repository.getAppointments();
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
      _appointments = await _repository.getAppointments();
      _endLoading();
    } on AppException catch (e) {
      _endLoading(e.message);
    } catch (e) {
      _endLoading('Unexpected error cancelling booking');
    }
  }

  void setCurrentUser(User user) {
    currentUser = user;
    loadAppointments();
  }

  bool isSlotAvailable({
    required DateTime slotStart,
    required int slotDuration,
    required String professionalId,
    String? excludeAppointmentId,
  }) {
    return ScheduleHelper.isSlotAvailable(
      slotStart: slotStart,
      slotDuration: slotDuration,
      professionalId: professionalId,
      appointments: _appointments,
      excludeAppointmentId: excludeAppointmentId,
    );
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

    final available = isSlotAvailable(
      slotStart: newDateTime,
      slotDuration: appointment.durationMinutes,
      professionalId: appointment.professionalId!,
      excludeAppointmentId: appointment.id,
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
}
