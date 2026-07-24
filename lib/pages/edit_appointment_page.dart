import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../helpers/format_helper.dart';
import '../helpers/schedule_helper.dart';
import '../models/appointment.dart';
import '../models/user.dart';
import '../providers/appointment_provider.dart';

class EditAppointmentPage extends StatefulWidget {
  const EditAppointmentPage({super.key, required this.appointment});

  final Appointment appointment;

  @override
  State<EditAppointmentPage> createState() => _EditAppointmentPageState();
}

class _EditAppointmentPageState extends State<EditAppointmentPage> {
  User? _professional;
  DateTime? _selectedDate;
  TimeOfDay? _selectedTime;
  bool _loadingProfessional = true;
  bool _saving = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _selectedDate = widget.appointment.dateTime;
    _selectedTime = TimeOfDay.fromDateTime(widget.appointment.dateTime);
    _loadProfessional();
  }

  Future<void> _loadProfessional() async {
    final repo = Provider.of<AppointmentProvider>(context, listen: false).repository;
    final professional = widget.appointment.professionalId == null
        ? null
        : await repo.getUserById(widget.appointment.professionalId!);

    if (!mounted) return;

    setState(() {
      _professional = professional;
      _loadingProfessional = false;
    });
  }

  Future<void> _pickDate() async {
    final now = DateTime.now();
    final date = await showDatePicker(
      context: context,
      initialDate: _selectedDate ?? now,
      firstDate: now,
      lastDate: DateTime(now.year + 2),
    );

    if (date != null) {
      setState(() {
        _selectedDate = date;
        _selectedTime = null;
      });
    }
  }

  DateTime _combine(DateTime date, TimeOfDay time) {
    return DateTime(date.year, date.month, date.day, time.hour, time.minute);
  }

  List<TimeOfDay> _availableSlots(User professional) {
    if (_selectedDate == null) return [];

    return ScheduleHelper.generateSlots(
      start: professional.workStart,
      end: professional.workEnd,
      slotMinutes: widget.appointment.durationMinutes,
    );
  }

  @override
  Widget build(BuildContext context) {
    final apptProvider = Provider.of<AppointmentProvider>(context);
    final appointment = widget.appointment;
    final professional = _professional;

    return Scaffold(
      appBar: AppBar(title: const Text('Reschedule booking')),
      body: _loadingProfessional
          ? const Center(child: CircularProgressIndicator())
          : professional == null
              ? const Center(
                  child: Text('Professional details are unavailable.'),
                )
              : SingleChildScrollView(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Card(
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                appointment.service,
                                style: Theme.of(context).textTheme.titleMedium,
                              ),
                              const SizedBox(height: 8),
                              Text('With ${appointment.professionalName}'),
                              Text(
                                'Current: ${FormatHelper.formatDateTime(appointment.dateTime)}',
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),
                      Card(
                        child: ListTile(
                          leading: const Icon(Icons.calendar_today),
                          title: const Text('New date'),
                          subtitle: Text(
                            _selectedDate == null
                                ? 'Tap to choose a date'
                                : FormatHelper.formatDate(_selectedDate!),
                          ),
                          trailing: const Icon(Icons.chevron_right),
                          onTap: _pickDate,
                        ),
                      ),
                      if (_selectedDate != null) ...[
                        const SizedBox(height: 16),
                        Text(
                          'Available slots (${appointment.durationMinutes} min)',
                          style: Theme.of(context).textTheme.titleSmall,
                        ),
                        const SizedBox(height: 8),
                        Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: _availableSlots(professional).map((slot) {
                            final slotDateTime =
                                _combine(_selectedDate!, slot);
                            final isBooked = !apptProvider.isSlotAvailable(
                              slotStart: slotDateTime,
                              slotDuration: appointment.durationMinutes,
                              professionalId: professional.id!,
                              excludeAppointmentId: appointment.id,
                            );
                            final isSelected = _selectedTime == slot;

                            return ChoiceChip(
                              label: Text(slot.format(context)),
                              selected: isSelected,
                              onSelected: isBooked
                                  ? null
                                  : (_) =>
                                      setState(() => _selectedTime = slot),
                            );
                          }).toList(),
                        ),
                      ],
                      const SizedBox(height: 20),
                      if (_error != null)
                        Text(_error!, style: const TextStyle(color: Colors.red)),
                      const SizedBox(height: 12),
                      ElevatedButton(
                        onPressed: _saving
                            ? null
                            : () async {
                                if (_selectedDate == null ||
                                    _selectedTime == null) {
                                  setState(() => _error =
                                      'Please select a new date and time');
                                  return;
                                }

                                setState(() {
                                  _saving = true;
                                  _error = null;
                                });

                                final newDateTime =
                                    _combine(_selectedDate!, _selectedTime!);
                                final result =
                                    await apptProvider.rescheduleAppointment(
                                  appointment: appointment,
                                  newDateTime: newDateTime,
                                );

                                if (!context.mounted) return;

                                setState(() => _saving = false);

                                if (result == null) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(
                                      content:
                                          Text('Booking rescheduled successfully'),
                                    ),
                                  );
                                  Navigator.pop(context, true);
                                } else {
                                  setState(() => _error = result);
                                }
                              },
                        child: _saving
                            ? const SizedBox(
                                height: 22,
                                width: 22,
                                child: CircularProgressIndicator(
                                  color: Colors.white,
                                  strokeWidth: 2,
                                ),
                              )
                            : const Text('Save new time'),
                      ),
                    ],
                  ),
                ),
    );
  }
}
