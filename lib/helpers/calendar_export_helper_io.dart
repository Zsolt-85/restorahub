import 'package:restorahub/models/appointment.dart';
import 'package:share_plus/share_plus.dart';
import 'package:url_launcher/url_launcher.dart';

import 'calendar_export_helper_common.dart';

Future<void> addToGoogleCalendar(Appointment appointment) async {
  final url = generateGoogleCalendarUrl(appointment);
  final uri = Uri.parse(url);
  if (await canLaunchUrl(uri)) {
    await launchUrl(uri, mode: LaunchMode.externalApplication);
  }
}

Future<void> exportCalendarIcs(Appointment appointment) async {
  final ics = generateIcsContent(appointment);
  await Share.share(ics, subject: appointment.service);
}
