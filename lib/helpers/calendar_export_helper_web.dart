import 'package:web/web.dart' as web;
import 'dart:js_interop';

import 'package:restorahub/models/appointment.dart';

import 'calendar_export_helper_common.dart';

Future<void> addToGoogleCalendar(Appointment appointment) async {
  final url = generateGoogleCalendarUrl(appointment);
  web.window.open(url, '_blank');
}

Future<void> exportCalendarIcs(Appointment appointment) async {
  final ics = generateIcsContent(appointment);
  final blob = web.Blob([ics].jsify() as JSArray<JSAny>, web.BlobPropertyBag(type: 'text/calendar;charset=utf-8'));
  final url = web.URL.createObjectURL(blob);
  web.HTMLAnchorElement()
    ..href = url
    ..setAttribute('download', 'event.ics')
    ..click();
  web.URL.revokeObjectURL(url);
}
