import 'dart:async';

import 'package:flutter/material.dart';

import '../exceptions/app_exception.dart';
import '../helpers/format_helper.dart';
import '../helpers/notification_schedule_helper.dart';
import '../models/appointment.dart';
import '../models/notification.dart';
import '../models/user.dart';
import '../repositories/booking_repository.dart';
import '../repositories/firestore_booking_repository.dart';
import '../repositories/user_repository.dart';
import '../repositories/firestore_user_repository.dart';
import '../repositories/notification_repository.dart';
import '../utils/app_logger.dart';

class AppointmentProvider extends ChangeNotifier {
  AppointmentProvider({
    BookingRepository? bookingRepository,
    UserRepository? userRepository,
    NotificationRepository? notificationRepository,
  })  : _repository = bookingRepository ?? FirestoreBookingRepository.instance,
        _userRepository = userRepository ?? FirestoreUserRepository.instance,
        _notificationRepository = notificationRepository;

  final BookingRepository _repository;
  final UserRepository _userRepository;
  final NotificationRepository? _notificationRepository;

  BookingRepository get repository => _repository;

  List<Appointment> _appointments = [];
  User? currentUser;

  List<Appointment> get appointments => _appointments;

  StreamSubscription<List<Appointment>>? _appointmentsSubscription;
  Stream<List<Appointment>>? _appointmentsStream;

  Stream<List<Appointment>>? get appointmentsStream => _appointmentsStream;

  bool _isLoading = false;
  String? _error;
  String? _errorMessage;

  bool get isLoading => _isLoading;
  String? get error => _error;
  String? get errorMessage => _errorMessage;

  void _beginLoading() {
    _isLoading = true;
    _error = null;
    _errorMessage = null;
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

  void startRealtimeAppointments() {
    _appointmentsSubscription?.cancel();
    if (currentUser == null) return;
    final userId = currentUser!.id;
    if (userId == null) return;

    if (currentUser!.role == 'customer') {
      _appointmentsStream = _repository.watchAppointmentsForCustomer(userId);
    } else if (currentUser!.isProfessional) {
      _appointmentsStream = _repository.watchAppointmentsForProfessional(userId);
    } else {
      return;
    }

    _appointmentsSubscription = _appointmentsStream!.listen(
      (appointments) {
        _appointments = appointments;
        notifyListeners();
      },
      onError: (e) {
        _error = e is AppException ? e.message : 'Unexpected error loading appointments';
        notifyListeners();
      },
    );
  }

  void stopRealtimeAppointments() {
    _appointmentsSubscription?.cancel();
    _appointmentsSubscription = null;
    _appointmentsStream = null;
  }

  Future<void> _sendNotification(AppNotification notification) async {
    if (_notificationRepository == null) return;
    try {
      await _notificationRepository!.sendNotification(notification);
    } catch (e) {
      AppLogger.error('AppointmentProvider._sendNotification error: $e');
    }
  }

  Future<void> addAppointment(Appointment appt) async {
    _beginLoading();
    try {
      await _repository.createAppointmentAtomic(appt);
      if (appt.professionalId != null && appt.customerId != null) {
        await _sendNotification(
          AppNotification(
            type: NotificationType.bookingRequested,
            title: 'New booking request',
            message: '${appt.customerName ?? 'A customer'} requested ${appt.service} on ${FormatHelper.formatDateTime(appt.dateTime)}',
            appointmentId: appt.id,
            receiverId: appt.professionalId!,
            senderId: appt.customerId!,
          ),
        );
      }
      await _reloadAppointments();
      _endLoading();
    } on AppException catch (e) {
      if (e.code == 'SLOT_TAKEN') {
        _errorMessage = 'This time slot is no longer available Details: $e';
      } else {
        _errorMessage = '${e.message} Details: ${e.toString()}';
      }
      _endLoading();
      rethrow;
    } catch (e) {
      _errorMessage = 'Raw Error: $e';
      _endLoading();
      rethrow;
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
      rethrow;
    } catch (e) {
      _endLoading('Unexpected error creating booking');
      rethrow;
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
      final previousStatus = appt.status;
      final updated = appt.withStatus(newStatus);
      await _repository.updateAppointment(updated);

      if (previousStatus == AppointmentStatus.pending &&
          newStatus == AppointmentStatus.confirmed &&
          appt.customerId != null &&
          appt.professionalId != null) {
        await _sendNotification(
          AppNotification(
            type: NotificationType.bookingConfirmed,
            title: 'Booking confirmed',
            message: '${appt.professionalName ?? 'Your professional'} confirmed ${appt.service} on ${FormatHelper.formatDateTime(appt.dateTime)}',
            appointmentId: appt.id,
            receiverId: appt.customerId!,
            senderId: appt.professionalId!,
          ),
        );
      }

      if (previousStatus == AppointmentStatus.pending &&
          newStatus == AppointmentStatus.cancelledByProfessional &&
          appt.customerId != null &&
          appt.professionalId != null) {
        await _sendNotification(
          AppNotification(
            type: NotificationType.bookingCancelled,
            title: 'Booking declined',
            message: '${appt.professionalName ?? 'Your professional'} declined ${appt.service} on ${FormatHelper.formatDateTime(appt.dateTime)}',
            appointmentId: appt.id,
            receiverId: appt.customerId!,
            senderId: appt.professionalId!,
          ),
        );
      }

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
        .where((a) => a.isCancelled)
        .toList();
  }

  List<Appointment> get pastAppointments {
    final now = DateTime.now();
    return _appointments
        .where((a) => a.dateTime.isBefore(now) || a.isTerminal)
        .toList()
      ..sort((a, b) => b.dateTime.compareTo(a.dateTime));
  }

  List<Appointment> get currentAppointments {
    final now = DateTime.now();
    return _appointments
        .where((a) => a.dateTime.isAfter(now) && !a.isCancelled)
        .toList();
  }

  List<Appointment> get upcomingAppointments {
    final now = DateTime.now();
    return _appointments
        .where((a) => !a.dateTime.isBefore(now) && !a.isTerminal)
        .toList()
      ..sort((a, b) => a.dateTime.compareTo(b.dateTime));
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
    int bufferTimeMinutes = 0,
  }) async {
    try {
      return await _repository.checkProfessionalAvailability(
        professionalId: professionalId,
        dateTime: slotStart,
        slotDurationMinutes: slotDuration,
        bufferTimeMinutes: bufferTimeMinutes,
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
    final appt = _appointments.firstWhere((a) => a.id == id);
    if (!appt.canBeCancelledByCustomer()) {
      return 'Appointments cannot be cancelled less than 2 hours before the start time.';
    }
    _beginLoading();
    try {
      final updated = appt.withStatus(AppointmentStatus.cancelledByCustomer);
      await _repository.updateAppointment(updated);
      await _reloadAppointments();
      _endLoading();
      return null;
    } on AppException catch (e) {
      _endLoading(e.message);
      return e.message;
    } catch (e) {
      _endLoading('Unexpected error cancelling booking');
      return 'Unexpected error cancelling booking';
    }
  }

  Future<String?> rescheduleAppointment({
    required Appointment appointment,
    required DateTime newDateTime,
  }) async {
    if (!appointment.canBeRescheduled()) {
      return 'This appointment cannot be rescheduled';
    }

    if (appointment.professionalId == null) {
      return 'Professional not found for this booking';
    }

    _beginLoading();
    try {
      final professional = await _userRepository.getUserById(appointment.professionalId!);
      final bufferTime = professional?.bufferTimeMinutes ?? 0;

      final available = await isSlotAvailable(
        slotStart: newDateTime,
        slotDuration: appointment.durationMinutes,
        professionalId: appointment.professionalId!,
        bufferTimeMinutes: bufferTime,
      );

      if (!available) {
        _endLoading('This time slot is no longer available');
        return 'This time slot is no longer available';
      }

      final updated = appointment.copyWith(dateTime: newDateTime);
      await _repository.updateAppointment(updated);
      await _reloadAppointments();
      _endLoading();
      return null;
    } on AppException catch (e) {
      _endLoading(e.message);
      return e.message;
    } catch (e) {
      _endLoading('Unexpected error rescheduling booking');
      return 'Unexpected error rescheduling booking';
    }
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
      if (appt.isCancelled) continue;
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
          AppLogger.error('Failed to schedule reminder: $e');
        }
      }
    }
  }

  @override
  void dispose() {
    _appointmentsSubscription?.cancel();
    super.dispose();
  }
}
