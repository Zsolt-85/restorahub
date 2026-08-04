import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../helpers/app_exception.dart';
import '../helpers/format_helper.dart';
import '../helpers/schedule_helper.dart';
import '../models/appointment.dart';
import '../models/booking_summary.dart';
import '../models/user.dart';
import '../providers/appointment_provider.dart';
import '../providers/auth_provider.dart';

class BookingPage extends StatefulWidget {
  final String service;

  const BookingPage({super.key, required this.service});

  @override
  State<BookingPage> createState() => _BookingPageState();
}

class _BookingPageState extends State<BookingPage> {
  DateTime? _selectedDate;
  TimeOfDay? _selectedTime;
  List<User> _professionals = [];
  User? _selectedProfessional;
  bool _loadingProfessionals = true;

  bool _loading = false;
  String? _error;

  late final String _category;

  @override
  void initState() {
    super.initState();
    _category = ScheduleHelper.parseServiceCategory(widget.service);
    _loadProfessionals();
  }

  Future<void> _loadProfessionals() async {
    final repo = Provider.of<AppointmentProvider>(context, listen: false).repository;
    try {
      final professionals = await repo.getProfessionalsBySpecialty(_category);

      if (!mounted) return;

      setState(() {
        _professionals = professionals;
        _loadingProfessionals = false;
        if (professionals.length == 1) {
          _selectedProfessional = professionals.first;
        } else {
          _selectedProfessional = null;
        }
        _selectedTime = null;
      });
    } on AppException catch (e) {
      if (!mounted) return;
      setState(() {
        _loadingProfessionals = false;
        _error = e.message;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _loadingProfessionals = false;
        _error = 'Failed to load professionals';
      });
    }
  }

  Future<void> _pickDate() async {
    final now = DateTime.now();

    final date = await showDatePicker(
      context: context,
      initialDate: now,
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

  DateTime _combine(DateTime d, TimeOfDay t) {
    return DateTime(d.year, d.month, d.day, t.hour, t.minute);
  }

  List<TimeOfDay> _slotsForProfessional(User professional) {
    return ScheduleHelper.generateSlots(
      start: professional.workStart,
      end: professional.workEnd,
      slotMinutes: professional.slotDurationMinutes,
    );
  }

  @override
  Widget build(BuildContext context) {
    final apptProvider = Provider.of<AppointmentProvider>(context);
    final auth = Provider.of<AuthProvider>(context, listen: false);
    final professional = _selectedProfessional;
    final timeSlots = professional == null
        ? <TimeOfDay>[]
        : _slotsForProfessional(professional);

    return Scaffold(
      appBar: AppBar(title: Text('Book ${widget.service}')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Card(
              color: Theme.of(context)
                  .colorScheme
                  .secondary
                  .withValues(alpha: 0.15),
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Text(
                  'Showing $_category professionals only',
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
              ),
            ),
            const SizedBox(height: 12),
            if (_loadingProfessionals)
              const Center(child: CircularProgressIndicator())
            else if (_professionals.isEmpty)
              Text(
                'No $_category professionals available yet.',
                style: const TextStyle(color: Colors.red),
              )
            else
              DropdownButtonFormField<User>(
                key: ValueKey(professional?.id),
                initialValue: _selectedProfessional,
                decoration: const InputDecoration(
                  labelText: 'Select professional',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.person_search),
                ),
                items: _professionals
                    .map(
                      (pro) => DropdownMenuItem(
                        value: pro,
                        child: Text(
                          '${pro.name} · ${pro.workStart.format(context)}–${pro.workEnd.format(context)} · ${pro.slotDurationMinutes} min slots',
                        ),
                      ),
                    )
                    .toList(),
                onChanged: (value) {
                  setState(() {
                    _selectedProfessional = value;
                    _selectedTime = null;
                  });
                },
              ),
            const SizedBox(height: 12),
            Card(
              child: ListTile(
                leading: const Icon(Icons.calendar_today),
                title: const Text('Date'),
                subtitle: Text(
                  _selectedDate == null
                      ? 'Tap to choose a date'
                      : FormatHelper.formatDate(_selectedDate!),
                ),
                trailing: const Icon(Icons.chevron_right),
                onTap: _pickDate,
              ),
            ),
            if (_selectedDate != null && professional != null) ...[
              const SizedBox(height: 16),
              Text(
                'Available slots (${professional.slotDurationMinutes} min each)',
                style: Theme.of(context).textTheme.titleSmall,
              ),
              const SizedBox(height: 8),
              if (timeSlots.isEmpty)
                const Text('No slots fit this professional schedule.')
              else
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: timeSlots.map((slot) {
                    final isSelected = _selectedTime == slot;

                    return ChoiceChip(
                      label: Text(slot.format(context)),
                      selected: isSelected,
                      onSelected: (_) => setState(() => _selectedTime = slot),
                    );
                  }).toList(),
                ),
            ],
            const SizedBox(height: 20),
            if (_error != null)
              Text(_error!, style: const TextStyle(color: Colors.red)),
            const SizedBox(height: 12),
            ElevatedButton(
              onPressed: _loading ||
                      _loadingProfessionals ||
                      _professionals.isEmpty
                  ? null
                  : () async {
                      if (_selectedProfessional == null) {
                        setState(() => _error = 'Please select a professional');
                        return;
                      }

                      if (_selectedDate == null || _selectedTime == null) {
                        setState(() =>
                            _error = 'Please select a date and time slot');
                        return;
                      }

                      final pro = _selectedProfessional!;
                      final dateTime = _combine(_selectedDate!, _selectedTime!);

                      if (!await apptProvider.isSlotAvailable(
                        slotStart: dateTime,
                        slotDuration: pro.slotDurationMinutes,
                        professionalId: pro.id!,
                      )) {
                        setState(() => _error =
                            'This slot was just booked. Pick another.');
                        return;
                      }

                      setState(() {
                        _loading = true;
                        _error = null;
                      });

                      final customer = auth.currentUser!;
                      final newAppt = Appointment(
                        service: widget.service,
                        dateTime: dateTime,
                        durationMinutes: pro.slotDurationMinutes,
                        customerId: customer.id,
                        customerName: customer.name,
                        customerPhone: customer.phone,
                        customerEmail: customer.email,
                        professionalId: pro.id,
                        professionalName: pro.name,
                        professionalPhone: pro.phone,
                        professionalEmail: pro.email,
                      );

                      try {
                        await apptProvider.addAppointment(newAppt);

                        if (!context.mounted) return;

                        Navigator.pushNamedAndRemoveUntil(
                          context,
                          '/success',
                          (route) => false,
                          arguments: BookingSummary(
                            service: widget.service,
                            professionalName: pro.name,
                            dateTime: dateTime,
                            durationMinutes: pro.slotDurationMinutes,
                          ),
                        );
                      } catch (e) {
                        setState(() => _error = 'Booking failed: $e');
                      }

                      if (mounted) setState(() => _loading = false);
                    },
              child: _loading
                  ? const SizedBox(
                      height: 22,
                      width: 22,
                      child: CircularProgressIndicator(
                        color: Colors.white,
                        strokeWidth: 2,
                      ),
                    )
                  : const Text('Confirm booking'),
            ),
          ],
        ),
      ),
    );
  }
}
