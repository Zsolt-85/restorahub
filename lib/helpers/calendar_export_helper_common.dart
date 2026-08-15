import 'package:restorahub/models/appointment.dart';

String generateGoogleCalendarUrl(Appointment appointment) {
  final title = Uri.encodeComponent('RestoraHub: ${appointment.service}');
  final start = _formatGoogleDate(appointment.dateTime);
  final end = _formatGoogleDate(appointment.endTime);
  final details = Uri.encodeComponent(
    'RestoraHub Booking\nService: ${appointment.service}\nDuration: ${appointment.durationMinutes} min',
  );
  final location = Uri.encodeComponent(appointment.professionalName ?? '');

  return 'https://calendar.google.com/calendar/render?action=TEMPLATE&text=$title&dates=$start/$end&details=$details&location=$location';
}

String generateIcsContent(Appointment appointment) {
  final now = DateTime.now().toUtc();
  final start = appointment.dateTime.toUtc();
  final end = appointment.endTime.toUtc();
  final uid = '${appointment.id ?? 'unknown'}@restorahub.app';

  return '''BEGIN:VCALENDAR
VERSION:2.0
PRODID:-//RestoraHub//EN
BEGIN:VEVENT
UID:$uid
DTSTAMP:${_formatIcsDate(now)}
DTSTART:${_formatIcsDate(start)}
DTEND:${_formatIcsDate(end)}
SUMMARY:RestoraHub: ${_escapeIcs(appointment.service)}
DESCRIPTION:RestoraHub Booking\\nService: ${_escapeIcs(appointment.service)}\\nDuration: ${appointment.durationMinutes} min
LOCATION:${_escapeIcs(appointment.professionalName ?? '')}
END:VEVENT
END:VCALENDAR''';
}

String _formatGoogleDate(DateTime date) {
  return '${date.year}${date.month.toString().padLeft(2, '0')}${date.day.toString().padLeft(2, '0')}T${date.hour.toString().padLeft(2, '0')}${date.minute.toString().padLeft(2, '0')}00';
}

String _formatIcsDate(DateTime date) {
  return '${date.year}${date.month.toString().padLeft(2, '0')}${date.day.toString().padLeft(2, '0')}T${date.hour.toString().padLeft(2, '0')}${date.minute.toString().padLeft(2, '0')}00Z';
}

String _escapeIcs(String value) {
  return value.replaceAll('\\', '\\\\').replaceAll(';', '\\;').replaceAll(',', '\\,');
}
