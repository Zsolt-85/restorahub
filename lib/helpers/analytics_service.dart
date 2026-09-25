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
  /// Working days assumed per week for capacity math. The capacity window
  /// (weekly slots vs. typically monthly-loaded appointments) is a known
  /// approximation — true period-aligned utilization belongs to Phase 6.
  static const int workingDaysPerWeek = 5;

  /// Fallback weekly capacity when a member's schedule is unparseable.
  /// Equals the old hardcoded 40 (8h day × 60min slots × 5 days).
  static const int fallbackWeeklySlotsPerStaff = 40;

  /// Weekly bookable slots derived from a member's own schedule.
  static int weeklyCapacityFor(User member) {
    final start = _parseMinutes(member.workStartTime);
    final end = _parseMinutes(member.workEndTime);
    final slot = member.slotDurationMinutes;
    if (start == null || end == null || slot <= 0 || end <= start) {
      return fallbackWeeklySlotsPerStaff;
    }
    final dailySlots = (end - start) ~/ slot;
    if (dailySlots <= 0) return fallbackWeeklySlotsPerStaff;
    return dailySlots * workingDaysPerWeek;
  }

  /// Collected cash for one payment. Shared by [aggregate],
  /// `PaymentProvider.totalRevenue`, and CSV export so every surface agrees.
  static double collectedFor(Payment payment) =>
      payment.depositAmount > 0 ? payment.depositAmount : payment.amount;

  static int? _parseMinutes(String value) {
    final match = RegExp(r'^(\d{1,2}):(\d{2})$').firstMatch(value.trim());
    if (match == null) return null;
    final hour = int.parse(match.group(1)!);
    final minute = int.parse(match.group(2)!);
    if (hour > 23 || minute > 59) return null;
    return hour * 60 + minute;
  }

  static AnalyticsMetrics aggregate({
    required List<Appointment> appointments,
    required List<Payment> payments,
    required List<User> staff,
    String? businessId,
  }) {
    final scopedAppointments = businessId == null
        ? appointments
        : appointments.where((a) => a.businessId == businessId).toList();
    final scopedPayments = businessId == null
        ? payments
        : payments.where((p) => p.businessId == businessId).toList();
    final scopedStaff = businessId == null
        ? staff
        : staff.where((u) => u.businessId == businessId).toList();

    final totalBookings = scopedAppointments.length;
    final completedBookings = scopedAppointments
        .where((a) => a.status == AppointmentStatus.completed)
        .length;
    final cancelledBookings =
        scopedAppointments.where((a) => a.isCancelled).length;
    final noShowBookings = scopedAppointments
        .where((a) => a.status == AppointmentStatus.noShow)
        .length;

    final completionRate =
        totalBookings > 0 ? completedBookings / totalBookings : 0.0;
    final cancellationRate =
        totalBookings > 0 ? cancelledBookings / totalBookings : 0.0;

    // Single source of truth per booking: a completed payment wins over the
    // appointment's price estimate. Summing both double-counted every paid
    // booking. Orphan payments (no matching appointment in range) still count.
    final completedPaymentsByAppointment = <String, List<Payment>>{};
    for (final payment in scopedPayments) {
      if (payment.status != PaymentStatus.completed) continue;
      completedPaymentsByAppointment
          .putIfAbsent(payment.appointmentId, () => [])
          .add(payment);
    }
    final knownAppointmentIds = <String>{
      for (final appt in scopedAppointments)
        if (appt.id != null) appt.id!,
    };
    final revenueByProfessional = <String, double>{};
    void addRevenue(String professionalId, double amount) {
      revenueByProfessional[professionalId] =
          (revenueByProfessional[professionalId] ?? 0.0) + amount;
    }
    // Revenue means collected cash: a completed payment with a partial
    // deposit counts the deposit (the balance may never arrive); a payment
    // without deposit counts its full amount.
    double collected(Payment payment) => collectedFor(payment);

    for (final appt in scopedAppointments) {
      if (appt.status != AppointmentStatus.completed) continue;
      final linked =
          appt.id == null ? null : completedPaymentsByAppointment[appt.id];
      if (linked != null && linked.isNotEmpty) {
        for (final payment in linked) {
          addRevenue(payment.professionalId, collected(payment));
        }
      } else if (appt.price != null) {
        addRevenue(appt.professionalId ?? 'unknown', appt.price!);
      }
    }
    for (final entry in completedPaymentsByAppointment.entries) {
      if (!knownAppointmentIds.contains(entry.key)) {
        for (final payment in entry.value) {
          addRevenue(payment.professionalId, collected(payment));
        }
      }
    }
    final revenueEstimate =
        revenueByProfessional.values.fold(0.0, (sum, val) => sum + val);

    final peakHours = <int, int>{};
    for (final appt in scopedAppointments) {
      final hour = appt.dateTime.hour;
      peakHours[hour] = (peakHours[hour] ?? 0) + 1;
    }

    final staffUtilization = <String, double>{};
    if (scopedStaff.isNotEmpty) {
      var totalCapacity = 0;
      final capacities = <String, int>{};
      for (final member in scopedStaff) {
        if (member.id == null) continue;
        final capacity = weeklyCapacityFor(member);
        capacities[member.id!] = capacity;
        totalCapacity += capacity;
      }
      final bookedSlots = scopedAppointments
          .where((a) => !a.isCancelled && a.professionalId != null)
          .length;
      staffUtilization['overall'] =
          totalCapacity > 0 ? bookedSlots / totalCapacity : 0.0;
      for (final member in scopedStaff) {
        if (member.id == null) continue;
        final memberAppts = scopedAppointments
            .where((a) => a.professionalId == member.id && !a.isCancelled)
            .length;
        final capacity = capacities[member.id!] ?? fallbackWeeklySlotsPerStaff;
        staffUtilization[member.id!] =
            capacity > 0 ? memberAppts / capacity : 0.0;
      }
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
