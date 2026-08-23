import 'package:web/web.dart' as web;
import 'dart:js_interop';

import 'package:restorahub/models/appointment.dart';
import 'package:restorahub/models/payment.dart';

import 'csv_export_helper_common.dart';

Future<void> exportAppointmentsCsv(List<Appointment> appointments, List<Payment> payments) async {
  final csv = generateAppointmentCsv(appointments, payments);
  final blob = web.Blob([csv].jsify() as JSArray<JSAny>, web.BlobPropertyBag(type: 'text/csv;charset=utf-8'));
  final url = web.URL.createObjectURL(blob);
  web.HTMLAnchorElement()
    ..href = url
    ..setAttribute('download', 'appointments_export.csv')
    ..click();
  web.URL.revokeObjectURL(url);
}
