import '../models/appointment.dart';

class BookingSummary {
  final String service;
  final String professionalName;
  final DateTime dateTime;
  final int durationMinutes;
  final AppointmentStatus status;

  const BookingSummary({
    required this.service,
    required this.professionalName,
    required this.dateTime,
    required this.durationMinutes,
    this.status = AppointmentStatus.pending,
  });
}
