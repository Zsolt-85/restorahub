import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../constants/routes.dart';
import '../exceptions/app_exception.dart';
import '../helpers/format_helper.dart';
import '../helpers/schedule_helper.dart';
import '../l10n/app_localizations.dart';
import '../models/appointment.dart';
import '../models/booking_summary.dart';
import '../models/user.dart';
import '../providers/appointment_provider.dart';
import '../providers/auth_provider.dart';
import '../repositories/user_repository.dart';
import '../utils/error_handler.dart';

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

  final Set<TimeOfDay> _unavailableSlots = {};

  late final String _category;

  @override
  void initState() {
    super.initState();
    _category = ScheduleHelper.parseServiceCategory(widget.service);
    _loadProfessionals();
  }

  Future<void> _loadProfessionals() async {
    final repo = Provider.of<UserRepository>(context, listen: false);
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
        _unavailableSlots.clear();
      });
      if (professionals.length == 1) {
        _loadSlotAvailability(professionals.first);
      }
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
        _unavailableSlots.clear();
      });
      if (_selectedProfessional != null) {
        _loadSlotAvailability(_selectedProfessional!);
      }
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
            !a.isTerminal;
      }).toList();

      final slots = _slotsForProfessional(professional);
      final unavailable = <TimeOfDay>{};

      for (final slot in slots) {
        final slotStart = _combine(_selectedDate!, slot);
        final isAvailable = ScheduleHelper.isSlotAvailable(
          slotStart: slotStart,
          slotDuration: professional.slotDurationMinutes,
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
    }
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
      appBar: AppBar(
        title: Text('${AppLocalizations.of(context)?.bookNow ?? 'Book Now'} ${widget.service}'),
      ),
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
                  '${AppLocalizations.of(context)?.showingProfessionalsOnly ?? 'Showing'} $_category ${AppLocalizations.of(context)?.professionalContact ?? 'professionals only'}',
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
              ),
            ),
            const SizedBox(height: 12),
            if (_loadingProfessionals)
              const Center(child: CircularProgressIndicator())
            else if (_professionals.isEmpty)
              Text(
                AppLocalizations.of(context)?.noServicesAvailable ??
                    'No services available',
                style: const TextStyle(color: Colors.red),
              )
            else
              DropdownButtonFormField<User>(
                key: ValueKey(professional?.id),
                initialValue: _selectedProfessional,
                decoration: InputDecoration(
                  labelText: AppLocalizations.of(context)?.selectCustomer ?? 'Select professional',
                  border: const OutlineInputBorder(),
                  prefixIcon: const Icon(Icons.person_search),
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
                    _unavailableSlots.clear();
                  });
                  if (value != null) {
                    _loadSlotAvailability(value);
                  }
                },
              ),
            const SizedBox(height: 12),
            Card(
              child: ListTile(
                leading: const Icon(Icons.calendar_today),
                title: Text(AppLocalizations.of(context)?.selectDate ?? 'Date'),
                subtitle: Text(
                  _selectedDate == null
                      ? AppLocalizations.of(context)?.selectDate ?? 'Tap to choose a date'
                      : FormatHelper.formatDate(_selectedDate!),
                ),
                trailing: const Icon(Icons.chevron_right),
                onTap: _pickDate,
              ),
            ),
            if (_selectedDate != null && professional != null) ...[
              const SizedBox(height: 16),
              Text(
                '${AppLocalizations.of(context)?.selectTimeSlot ?? 'Available slots'} (${professional.slotDurationMinutes} ${AppLocalizations.of(context)?.mins ?? 'min each'})',
                style: Theme.of(context).textTheme.titleSmall,
              ),
              const SizedBox(height: 8),
              if (timeSlots.isEmpty)
                Text(AppLocalizations.of(context)?.noAppointments ?? 'No slots fit this professional schedule.')
              else
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: timeSlots.map((slot) {
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
                                        .withValues(alpha: 0.38),
                                  ),
                                ),
                                 const SizedBox(width: 4),
                                Text(
                                  AppLocalizations.of(context)?.confirmed ?? 'Booked',
                                  style: TextStyle(
                                    fontSize: 10,
                                    color: Theme.of(context)
                                        .colorScheme
                                        .onSurface
                                        .withValues(alpha: 0.38),
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
              onPressed: _loading ||
                      _loadingProfessionals ||
                      _professionals.isEmpty
                  ? null
                  : () async {
                      if (_selectedProfessional == null) {
                        setState(() => _error = AppLocalizations.of(context)?.selectCustomer ?? 'Please select a professional');
                        return;
                      }

                      if (_selectedDate == null || _selectedTime == null) {
                        setState(() => _error = AppLocalizations.of(context)?.selectDate ?? 'Please select a date and time slot');
                        return;
                      }

                      final pro = _selectedProfessional!;
                      final dateTime = _combine(_selectedDate!, _selectedTime!);

                      if (!await apptProvider.isSlotAvailable(
                        slotStart: dateTime,
                        slotDuration: pro.slotDurationMinutes,
                        professionalId: pro.id!,
                        bufferTimeMinutes: pro.bufferTimeMinutes,
                      )) {
                        setState(() => _error =
                            AppLocalizations.of(context)?.confirmed ?? 'This slot was just booked. Pick another.');
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
                        status: AppointmentStatus.pending,
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
                        final navigator = Navigator.of(context);

                        await apptProvider.addAppointment(newAppt);

                        if (!mounted) return;

                        navigator.pushNamedAndRemoveUntil(
                          Routes.success,
                          (route) => false,
                          arguments: BookingSummary(
                            service: widget.service,
                            professionalName: pro.name,
                            professionalId: pro.id,
                            dateTime: dateTime,
                            durationMinutes: pro.slotDurationMinutes,
                            customerName: customer.name,
                            customerPhone: customer.phone,
                            professionalPhone: pro.phone,
                            professionalEmail: pro.email,
                          ),
                        );
                      } catch (e) {
                        if (mounted) {
                          final displayError = apptProvider.errorMessage ?? ErrorHandler.getDisplayMessage(e);
                          ErrorHandler.showErrorSnackBar(context, displayError);
                          setState(() => _error = displayError);
                        }
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
                  : Text(AppLocalizations.of(context)?.confirmBooking ?? 'Confirm booking'),
            ),
          ],
        ),
      ),
    );
  }
}
