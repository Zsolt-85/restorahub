import 'dart:html' as html;
import 'package:restorahub/models/appointment.dart';

import 'calendar_export_helper_common.dart';

Future<void> addToGoogleCalendar(Appointment appointment) async {
  final url = generateGoogleCalendarUrl(appointment);
  html.window.open(url, '_blank');
}

Future<void> exportCalendarIcs(Appointment appointment) async {
  final ics = generateIcsContent(appointment);
  final blob = html.Blob([ics], 'text/calendar;charset=utf-8');
  final url = html.Url.createObjectUrlFromBlob(blob);
  html.AnchorElement(href: url)
    ..setAttribute('download', 'event.ics')
    ..click();
  html.Url.revokeObjectUrl(url);
}
