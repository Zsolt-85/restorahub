import 'package:restorahub/models/appointment.dart';
import 'package:restorahub/models/payment.dart';

String generateAppointmentCsv(List<Appointment> appointments, List<Payment> payments) {
  final buffer = StringBuffer();
  buffer.writeln('Date,Service,Category,Professional,Status,Price,Currency');

  final paymentMap = <String, Payment>{};
  for (final p in payments) {
    if (p.status == PaymentStatus.completed) {
      paymentMap[p.appointmentId] = p;
    }
  }

  for (final appt in appointments) {
    final date = '${appt.dateTime.year.toString().padLeft(4, '0')}-${appt.dateTime.month.toString().padLeft(2, '0')}-${appt.dateTime.day.toString().padLeft(2, '0')}';
    final category = _extractCategory(appt.service);
    final status = appt.status.displayLabel;
    final payment = paymentMap[appt.id ?? ''];
    final price = payment != null ? payment.amount.toStringAsFixed(2) : '';
    final currency = payment?.currency ?? '';

    final serviceField = '"${appt.service.replaceAll('"', '""')}"';
    final professionalField = '"${(appt.professionalName ?? '').replaceAll('"', '""')}"';

    buffer.writeln('$date,$serviceField,"$category",$professionalField,$status,$price,$currency');
  }

  return buffer.toString();
}

String _extractCategory(String service) {
  final parts = service.split(' — ');
  return parts.first.trim();
}
