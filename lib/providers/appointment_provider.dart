import 'package:flutter/material.dart';

import '../helpers/schedule_helper.dart';
import '../models/appointment.dart';
import '../models/user.dart';
import '../repositories/booking_repository.dart';
import '../repositories/local_booking_repository.dart';

class AppointmentProvider extends ChangeNotifier {
  AppointmentProvider({BookingRepository? repository})
      : _repository = repository ?? LocalBookingRepository.instance;

  final BookingRepository _repository;

  List<Appointment> _appointments = [];
  User? currentUser;

  List<Appointment> get appointments => _appointments;

  Future<void> loadAppointments() async {
    _appointments = await _repository.getAppointments();
    notifyListeners();
  }

  Future<void> addAppointment(Appointment appt) async {
    await _repository.insertAppointment(appt);
    await loadAppointments();
  }

  Future<void> updateAppointment(Appointment appt) async {
    await _repository.updateAppointment(appt);
    await loadAppointments();
  }

  Future<void> deleteAppointment(int id) async {
    await _repository.deleteAppointment(id);
    await loadAppointments();
  }

  void setCurrentUser(User user) {
    currentUser = user;
    loadAppointments();
    notifyListeners();
  }

  bool isSlotAvailable({
    required DateTime slotStart,
    required int slotDuration,
    required int professionalId,
    int? excludeAppointmentId,
  }) {
    return ScheduleHelper.isSlotAvailable(
      slotStart: slotStart,
      slotDuration: slotDuration,
      professionalId: professionalId,
      appointments: _appointments,
      excludeAppointmentId: excludeAppointmentId,
    );
  }

  Future<String?> cancelAppointment(int id) async {
    await _repository.deleteAppointment(id);
    await loadAppointments();
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
    await _repository.updateAppointment(updated);
    await loadAppointments();
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
