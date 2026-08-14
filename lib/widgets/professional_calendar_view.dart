import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:table_calendar/table_calendar.dart';

import '../helpers/format_helper.dart';
import '../l10n/app_localizations.dart';
import '../models/appointment.dart';
import '../models/user.dart';
import '../providers/appointment_provider.dart';

class ProfessionalCalendarView extends StatefulWidget {
  const ProfessionalCalendarView({
    super.key,
    required this.professional,
  });

  final User professional;

  @override
  State<ProfessionalCalendarView> createState() =>
      _ProfessionalCalendarViewState();
}

class _ProfessionalCalendarViewState extends State<ProfessionalCalendarView> {
  CalendarFormat _calendarFormat = CalendarFormat.month;
  DateTime _focusedDay = DateTime.now();
  DateTime? _selectedDay;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        _buildCalendar(context),
        const Divider(height: 1),
        Expanded(child: _buildDailyAgenda(context)),
      ],
    );
  }

  Widget _buildCalendar(BuildContext context) {
    final apptProvider = context.watch<AppointmentProvider>();
    final appointments = apptProvider.filteredAppointments;

    List<Appointment> eventLoader(DateTime day) {
      return appointments.where((a) {
        final apptDay = DateTime(a.dateTime.year, a.dateTime.month, a.dateTime.day);
        final targetDay = DateTime(day.year, day.month, day.day);
        return apptDay == targetDay;
      }).toList();
    }

    final now = DateTime.now();

    return TableCalendar(
      firstDay: DateTime(now.year, now.month - 2),
      lastDay: DateTime(now.year + 2, now.month, now.day),
      focusedDay: _focusedDay,
      selectedDayPredicate: (day) => isSameDay(_selectedDay, day),
      calendarFormat: _calendarFormat,
      startingDayOfWeek: StartingDayOfWeek.monday,
      eventLoader: eventLoader,
      calendarStyle: CalendarStyle(
        markersMaxCount: 3,
        markerDecoration: BoxDecoration(
          color: Theme.of(context).colorScheme.primary,
          shape: BoxShape.circle,
        ),
        todayDecoration: BoxDecoration(
          color: Theme.of(context).colorScheme.primaryContainer,
          shape: BoxShape.circle,
        ),
        selectedDecoration: BoxDecoration(
          color: Theme.of(context).colorScheme.primary,
          shape: BoxShape.circle,
        ),
      ),
      headerStyle: const HeaderStyle(
        formatButtonVisible: true,
        formatButtonShowsNext: false,
        titleCentered: true,
      ),
      onDaySelected: (selectedDay, focusedDay) {
        setState(() {
          _selectedDay = selectedDay;
          _focusedDay = focusedDay;
        });
      },
      onFormatChanged: (format) {
        setState(() {
          _calendarFormat = format;
        });
      },
      onPageChanged: (focusedDay) {
        setState(() {
          _focusedDay = focusedDay;
        });
      },
    );
  }

  Widget _buildDailyAgenda(BuildContext context) {
    final apptProvider = context.watch<AppointmentProvider>();
    final day = _selectedDay ?? _focusedDay;

    final dayAppointments = apptProvider.filteredAppointments.where((a) {
      final apptDay = DateTime(a.dateTime.year, a.dateTime.month, a.dateTime.day);
      final targetDay = DateTime(day.year, day.month, day.day);
      return apptDay == targetDay;
    }).toList();

    dayAppointments.sort((a, b) => a.dateTime.compareTo(b.dateTime));

    final timeSlots = _generateTimeSlots();

    if (timeSlots.isEmpty) {
      return Center(
        child: Text(AppLocalizations.of(context)?.noWorkingHours ?? 'No working hours configured'),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: timeSlots.length,
      itemBuilder: (context, index) {
        final slot = timeSlots[index];
        final slotAppointments = dayAppointments.where((a) {
          final apptHour = a.dateTime.hour;
          final apptMinute = a.dateTime.minute;
          final slotHour = slot.hour;
          final slotMinute = slot.minute;
          return apptHour == slotHour && apptMinute == slotMinute;
        }).toList();

        return _TimeSlotRow(
          slot: slot,
          appointments: slotAppointments,
          slotDuration: widget.professional.slotDurationMinutes,
        );
      },
    );
  }

  List<DateTime> _generateTimeSlots() {
    final slots = <DateTime>[];
    final startHour = int.tryParse(widget.professional.workStartTime.split(':').first) ?? 9;
    final startMinute = int.tryParse(widget.professional.workStartTime.split(':').last) ?? 0;
    final endHour = int.tryParse(widget.professional.workEndTime.split(':').first) ?? 17;
    final endMinute = int.tryParse(widget.professional.workEndTime.split(':').last) ?? 0;

    final start = DateTime(_focusedDay.year, _focusedDay.month, _focusedDay.day, startHour, startMinute);
    final end = DateTime(_focusedDay.year, _focusedDay.month, _focusedDay.day, endHour, endMinute);

    final slotMinutes = widget.professional.slotDurationMinutes;
    var current = start;
    while (current.isBefore(end)) {
      slots.add(current);
      current = current.add(Duration(minutes: slotMinutes));
    }

    return slots;
  }
}

class _TimeSlotRow extends StatelessWidget {
  const _TimeSlotRow({
    required this.slot,
    required this.appointments,
    required this.slotDuration,
  });

  final DateTime slot;
  final List<Appointment> appointments;
  final int slotDuration;

  @override
  Widget build(BuildContext context) {
    final timeLabel = TimeOfDay(hour: slot.hour, minute: slot.minute);
    final formattedTime = '${timeLabel.hourOfPeriod.toString().padLeft(2, '0')}:${timeLabel.minute.toString().padLeft(2, '0')} ${timeLabel.period == DayPeriod.am ? AppLocalizations.of(context)?.am ?? 'AM' : AppLocalizations.of(context)?.pm ?? 'PM'}';

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 64,
          child: Text(
            formattedTime,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: Colors.grey[600],
                  fontWeight: FontWeight.w500,
                ),
          ),
        ),
        const SizedBox(width: 12),
        Container(
          width: 2,
          height: appointments.isEmpty ? 48 : null,
          color: Colors.grey[300],
        ),
        const SizedBox(width: 12),
        Expanded(
          child: appointments.isEmpty
              ? Container(
                  height: 48,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(8),
                    color: Colors.grey[50],
                  ),
                )
              : Column(
                  children: appointments.map((appt) {
                    return _AppointmentSlot(appointment: appt, slotDuration: slotDuration);
                  }).toList(),
                ),
        ),
      ],
    );
  }
}

class _AppointmentSlot extends StatelessWidget {
  const _AppointmentSlot({
    required this.appointment,
    required this.slotDuration,
  });

  final Appointment appointment;
  final int slotDuration;

  @override
  Widget build(BuildContext context) {
    final statusColor = _statusColor(appointment.status);
    final endLabel = appointment.dateTime.add(Duration(minutes: appointment.durationMinutes));
    final endTime = TimeOfDay(hour: endLabel.hour, minute: endLabel.minute);
    final endFormatted = '${endTime.hourOfPeriod.toString().padLeft(2, '0')}:${endTime.minute.toString().padLeft(2, '0')} ${endTime.period == DayPeriod.am ? 'AM' : 'PM'}';

    return GestureDetector(
      onTap: () => _showAppointmentDetail(context, appointment),
      child: Container(
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(8),
          color: statusColor.withValues(alpha: 0.1),
          border: Border(left: BorderSide(color: statusColor, width: 4)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    appointment.service,
                    style: const TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 14,
                    ),
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                    color: statusColor.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    appointment.status.displayLabel,
                    style: TextStyle(
                      color: statusColor,
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 4),
             Text(
               '${appointment.customerName ?? AppLocalizations.of(context)?.unknownValue ?? "Unknown"} · ${appointment.durationMinutes} ${AppLocalizations.of(context)?.minutesLabel ?? 'min'}',
               style: Theme.of(context).textTheme.bodySmall,
             ),
            Text(
              endFormatted,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Colors.grey[600],
                    fontSize: 12,
                  ),
            ),
          ],
        ),
      ),
    );
  }

  void _showAppointmentDetail(BuildContext context, Appointment appointment) {
    final endTime = appointment.dateTime.add(Duration(minutes: appointment.durationMinutes));
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (ctx) {
        return DraggableScrollableSheet(
          initialChildSize: 0.5,
          minChildSize: 0.3,
          maxChildSize: 0.8,
          expand: false,
          builder: (context, scrollController) {
            return Padding(
              padding: const EdgeInsets.all(24),
              child: ListView(
                controller: scrollController,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          appointment.service,
                          style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                                fontWeight: FontWeight.bold,
                              ),
                        ),
                      ),
                      _StatusChip(label: _localizedStatus(context, appointment.status)),
                    ],
                  ),
                  const SizedBox(height: 16),
                   _DetailRow(
                     icon: Icons.person_outline,
                     label: AppLocalizations.of(context)?.counterpartyCustomer ?? 'Customer',
                     value: appointment.customerName ?? AppLocalizations.of(context)?.notSetValue ?? 'N/A',
                   ),
                   _DetailRow(
                     icon: Icons.phone_outlined,
                     label: AppLocalizations.of(context)?.phone ?? 'Phone',
                     value: appointment.customerPhone ?? AppLocalizations.of(context)?.notSetValue ?? 'N/A',
                   ),
                   _DetailRow(
                     icon: Icons.email_outlined,
                     label: AppLocalizations.of(context)?.email ?? 'Email',
                     value: appointment.customerEmail ?? AppLocalizations.of(context)?.notSetValue ?? 'N/A',
                   ),
                  const SizedBox(height: 8),
                   _DetailRow(
                     icon: Icons.calendar_today_outlined,
                     label: AppLocalizations.of(context)?.selectDate ?? 'Date',
                     value: FormatHelper.formatDate(appointment.dateTime),
                   ),
                   _DetailRow(
                     icon: Icons.access_time_outlined,
                     label: AppLocalizations.of(context)?.timeLabel ?? 'Time',
                     value: '${FormatHelper.formatTime(appointment.dateTime)} - ${FormatHelper.formatTime(endTime)}',
                   ),
                   _DetailRow(
                     icon: Icons.timer_outlined,
                     label: AppLocalizations.of(context)?.duration ?? 'Duration',
                     value: '${appointment.durationMinutes} ${AppLocalizations.of(context)?.minutesLabel ?? 'minutes'}',
                   ),
                ],
              ),
            );
          },
        );
      },
    );
  }
}

class _StatusChip extends StatelessWidget {
  const _StatusChip({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    final color = _statusColorFromLabel(label);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: color,
          fontWeight: FontWeight.w600,
          fontSize: 13,
        ),
      ),
    );
  }
}

Color _statusColorFromLabel(String label) {
  final l = label.toLowerCase();
  if (l.contains('pending') || l.contains('függő') || l.contains('ausstehend') || l.contains('în așteptare')) return Colors.orange;
  if (l.contains('confirmed') || l.contains('megerősített') || l.contains('bestätigt') || l.contains('confirmată')) return Colors.green;
  if (l.contains('completed') || l.contains('befejezett') || l.contains('abgeschlossen') || l.contains('finalizată')) return Colors.blue;
  if (l.contains('cancelled') || l.contains('törölve') || l.contains('storniert') || l.contains('anulată')) return Colors.red;
  return Colors.grey;
}

class _DetailRow extends StatelessWidget {
  const _DetailRow({
    required this.icon,
    required this.label,
    required this.value,
  });

  final IconData icon;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          Icon(icon, size: 20, color: Colors.grey[600]),
          const SizedBox(width: 12),
          Expanded(
            child: RichText(
              text: TextSpan(
                style: Theme.of(context).textTheme.bodyMedium,
                children: [
                  TextSpan(
                    text: '$label: ',
                    style: const TextStyle(fontWeight: FontWeight.w600),
                  ),
                  TextSpan(text: value),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

Color _statusColor(AppointmentStatus status) {
  switch (status) {
    case AppointmentStatus.pending:
      return Colors.orange;
    case AppointmentStatus.confirmed:
      return Colors.green;
    case AppointmentStatus.completed:
      return Colors.blue;
    case AppointmentStatus.cancelledByCustomer:
    case AppointmentStatus.cancelledByProfessional:
      return Colors.red;
    case AppointmentStatus.noShow:
      return Colors.grey;
  }
}

String _localizedStatus(BuildContext context, AppointmentStatus status) {
  final l10n = AppLocalizations.of(context);
  switch (status) {
    case AppointmentStatus.pending:
      return l10n?.statusPending ?? 'Pending';
    case AppointmentStatus.confirmed:
      return l10n?.statusConfirmed ?? 'Confirmed';
    case AppointmentStatus.completed:
      return l10n?.statusCompleted ?? 'Completed';
    case AppointmentStatus.cancelledByCustomer:
    case AppointmentStatus.cancelledByProfessional:
      return l10n?.statusCancelled ?? 'Cancelled';
    case AppointmentStatus.noShow:
      return 'No Show';
  }
}
