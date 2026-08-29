import '../models/appointment.dart';
import '../models/payment.dart';
import '../models/user.dart';

class AnalyticsMetrics {
  final int totalBookings;
  final double revenueEstimate;
  final Map<int, int> peakHours;
  final Map<String, double> staffUtilization;
  final int completedBookings;
  final int cancelledBookings;
  final int noShowBookings;
  final double completionRate;
  final double cancellationRate;

  AnalyticsMetrics({
    required this.totalBookings,
    required this.revenueEstimate,
    required this.peakHours,
    required this.staffUtilization,
    required this.completedBookings,
    required this.cancelledBookings,
    required this.noShowBookings,
    required this.completionRate,
    required this.cancellationRate,
  });
}

class AnalyticsService {
  static AnalyticsMetrics aggregate({
    required List<Appointment> appointments,
    required List<Payment> payments,
    required List<User> staff,
  }) {
    final totalBookings = appointments.length;
    final completedBookings = appointments.where((a) => a.status == AppointmentStatus.completed).length;
    final cancelledBookings = appointments.where((a) => a.isCancelled).length;
    final noShowBookings = appointments.where((a) => a.status == AppointmentStatus.noShow).length;

    final completionRate = totalBookings > 0 ? completedBookings / totalBookings : 0.0;
    final cancellationRate = totalBookings > 0 ? cancelledBookings / totalBookings : 0.0;

    final revenueByAppointment = <String, double>{};
    for (final appt in appointments) {
      if (appt.status == AppointmentStatus.completed && appt.price != null) {
        final professionalId = appt.professionalId ?? 'unknown';
        revenueByAppointment[professionalId] = (revenueByAppointment[professionalId] ?? 0.0) + appt.price!;
      }
    }
    for (final payment in payments) {
      if (payment.status == PaymentStatus.completed) {
        revenueByAppointment[payment.professionalId] = (revenueByAppointment[payment.professionalId] ?? 0.0) + payment.amount;
      }
    }
    final revenueEstimate = revenueByAppointment.values.fold(0.0, (sum, val) => sum + val);

    final peakHours = <int, int>{};
    for (final appt in appointments) {
      final hour = appt.dateTime.hour;
      peakHours[hour] = (peakHours[hour] ?? 0) + 1;
    }

    final staffUtilization = <String, double>{};
    if (staff.isNotEmpty) {
      final totalPossibleSlots = staff.length * 40;
      final bookedSlots = appointments.where((a) => !a.isCancelled && a.professionalId != null).length;
      staffUtilization['overall'] = totalPossibleSlots > 0 ? bookedSlots / totalPossibleSlots : 0.0;
    }
    for (final member in staff) {
      if (member.id == null) continue;
      final memberAppts = appointments.where((a) => a.professionalId == member.id && !a.isCancelled).length;
      staffUtilization[member.id!] = memberAppts / 40.0;
    }

    return AnalyticsMetrics(
      totalBookings: totalBookings,
      revenueEstimate: revenueEstimate,
      peakHours: peakHours,
      staffUtilization: staffUtilization,
      completedBookings: completedBookings,
      cancelledBookings: cancelledBookings,
      noShowBookings: noShowBookings,
      completionRate: completionRate,
      cancellationRate: cancellationRate,
    );
  }
}
