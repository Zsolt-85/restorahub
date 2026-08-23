import 'package:restorahub/models/appointment.dart';
import 'package:restorahub/models/payment.dart';
import 'package:share_plus/share_plus.dart';

import 'csv_export_helper_common.dart';

Future<void> exportAppointmentsCsv(List<Appointment> appointments, List<Payment> payments) async {
  final csv = generateAppointmentCsv(appointments, payments);
  await Share.share(csv, subject: 'Appointments Export');
}
