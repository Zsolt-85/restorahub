import '../models/appointment.dart';

class BookingSummary {
  final String service;
  final String professionalName;
  final String? professionalId;
  final DateTime dateTime;
  final int durationMinutes;
  final AppointmentStatus status;
  final String? customerName;
  final String? customerPhone;
  final String? professionalPhone;
  final String? professionalEmail;

  const BookingSummary({
    required this.service,
    required this.professionalName,
    this.professionalId,
    required this.dateTime,
    required this.durationMinutes,
    this.status = AppointmentStatus.pending,
    this.customerName,
    this.customerPhone,
    this.professionalPhone,
    this.professionalEmail,
  });

  Appointment toAppointment({String? id, String? customerId}) {
    return Appointment(
      id: id,
      service: service,
      dateTime: dateTime,
      durationMinutes: durationMinutes,
      status: status,
      customerId: customerId,
      customerName: customerName,
      customerPhone: customerPhone,
      professionalId: professionalId,
      professionalName: professionalName,
      professionalPhone: professionalPhone,
      professionalEmail: professionalEmail,
    );
  }
}
