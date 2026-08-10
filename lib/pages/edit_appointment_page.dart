import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../helpers/format_helper.dart';
import '../helpers/schedule_helper.dart';
import '../models/appointment.dart';
import '../models/user.dart';
import '../providers/appointment_provider.dart';
import '../repositories/user_repository.dart';
import '../utils/error_handler.dart';

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

  final Set<TimeOfDay> _unavailableSlots = {};

  @override
  void initState() {
    super.initState();
    _selectedDate = widget.appointment.dateTime;
    _selectedTime = TimeOfDay.fromDateTime(widget.appointment.dateTime);
    _loadProfessional();
  }

  Future<void> _loadProfessional() async {
    final repo = Provider.of<UserRepository>(context, listen: false);
    final professional = widget.appointment.professionalId == null
        ? null
        : await repo.getUserById(widget.appointment.professionalId!);

    if (!mounted) return;

    setState(() {
      _professional = professional;
      _loadingProfessional = false;
      _unavailableSlots.clear();
    });
    if (professional != null) {
      _loadSlotAvailability(professional);
    }
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
        _unavailableSlots.clear();
      });
      if (_professional != null) {
        _loadSlotAvailability(_professional!);
      }
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
      breakStart: professional.breakStart,
      breakEnd: professional.breakEnd,
    );
  }

  Future<void> _loadSlotAvailability(User professional) async {
    if (_selectedDate == null) {
      setState(() => _unavailableSlots.clear());
      return;
    }

    try {
      final repo = Provider.of<AppointmentProvider>(context, listen: false).repository;
      final allAppointments = await repo.getAppointmentsForProfessional(professional.id!);

      final dateStr = _selectedDate!;
      final dayAppointments = allAppointments.where((a) {
        return a.dateTime.year == dateStr.year &&
            a.dateTime.month == dateStr.month &&
            a.dateTime.day == dateStr.day &&
            !a.isTerminal &&
            a.id != widget.appointment.id;
      }).toList();

      final slots = _availableSlots(professional);
      final unavailable = <TimeOfDay>{};

      for (final slot in slots) {
        final slotStart = _combine(_selectedDate!, slot);
        final isAvailable = ScheduleHelper.isSlotAvailable(
          slotStart: slotStart,
          slotDuration: widget.appointment.durationMinutes,
          professionalId: professional.id!,
          appointments: dayAppointments,
          bufferTimeMinutes: professional.bufferTimeMinutes,
        );

        if (!isAvailable) {
          unavailable.add(slot);
        }
      }

      if (mounted) {
        setState(() {
          _unavailableSlots
            ..clear()
            ..addAll(unavailable);
        });
      }
    } catch (e) {
      // Keep existing unavailable slots on error;
      // the final check before booking still protects against double booking.
    } finally {
      if (mounted) {
        setState(() {});
      }
    }
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
                            final isSelected = _selectedTime == slot;
                            final isUnavailable = _unavailableSlots.contains(slot);

                             return ChoiceChip(
                              label: isUnavailable
                                  ? Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Text(
                                          slot.format(context),
                                          style: TextStyle(
                                            color: Theme.of(context)
                                                .colorScheme
                                                .onSurface
                                                .withOpacity(0.38),
                                          ),
                                        ),
                                        const SizedBox(width: 4),
                                        Text(
                                          'Booked',
                                          style: TextStyle(
                                            fontSize: 10,
                                            color: Theme.of(context)
                                                .colorScheme
                                                .onSurface
                                                .withOpacity(0.38),
                                          ),
                                        ),
                                      ],
                                    )
                                  : isSelected
                                      ? Text(
                                          slot.format(context),
                                          style: TextStyle(color: Theme.of(context).colorScheme.onPrimary),
                                        )
                                      : Text(slot.format(context)),
                              selected: isSelected,
                              onSelected: isUnavailable ? null : (_) => setState(() => _selectedTime = slot),
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
                                  setState(() => _error = ErrorHandler.getDisplayMessage(result));
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
