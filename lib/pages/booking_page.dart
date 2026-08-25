import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../constants/routes.dart';
import '../widgets/tenant_brand_header.dart';
import '../exceptions/app_exception.dart';
import '../helpers/format_helper.dart';
import '../helpers/schedule_helper.dart';
import '../l10n/app_localizations.dart';
import '../models/appointment.dart';
import '../models/booking_summary.dart';
import '../models/service.dart';
import '../models/user.dart';
import '../providers/appointment_provider.dart';
import '../providers/auth_provider.dart';
import '../providers/service_provider.dart';
import '../repositories/user_repository.dart';
import '../utils/error_handler.dart';

class BookingPage extends StatefulWidget {
  final String? service;
  final String? category;
  final String? appointmentId;

  const BookingPage({super.key, this.service, this.category, this.appointmentId});

  @override
  State<BookingPage> createState() => _BookingPageState();
}

class _BookingPageState extends State<BookingPage> {
  DateTime? _selectedDate;
  TimeOfDay? _startTime;
  TimeOfDay? _endTime;
  List<User> _professionals = [];
  User? _selectedProfessional;
  bool _loadingProfessionals = true;

  Service? _selectedService;

  bool _loading = false;
  bool _loadingAppointment = false;
  String? _error;
  String? _rangeError;

  List<Appointment> _dayAppointments = [];

  late String _category;
  bool get _isReschedule => widget.appointmentId != null && widget.appointmentId!.isNotEmpty;
  Appointment? _rescheduleAppointment;

  @override
  void initState() {
    super.initState();
    _category = widget.category ??
        (widget.service?.isNotEmpty == true
            ? ScheduleHelper.parseServiceCategory(widget.service!)
            : '');
    if (_isReschedule) {
      _selectedService = widget.service != null && widget.service!.isNotEmpty
          ? Service(name: widget.service!)
          : null;
      _loadAppointmentForReschedule();
    } else {
      _loadProfessionals();
    }
  }

  String _serviceSubtype(String service) {
    if (service.contains('\u2014')) {
      return service.split('\u2014').last.trim();
    }
    return service;
  }
  Future<void> _loadAppointmentForReschedule() async {
    setState(() => _loadingAppointment = true);
    try {
      final apptProvider = Provider.of<AppointmentProvider>(context, listen: false);
      final appt = await apptProvider.getAppointmentById(widget.appointmentId!);
      if (appt == null) {
        if (!mounted) return;
        setState(() => _error = 'Failed to load appointment details');
        return;
      }

      String resolvedCategory = _category;

      if (!ServiceProvider.defaultServices.any((s) => s.name == resolvedCategory)) {
        String baseService = appt.service;
        if (baseService.contains('\u2014')) {
          baseService = baseService.split('\u2014').first.trim();
        }
        resolvedCategory = ServiceProvider.getCategoryForService(baseService);
      }

      if (appt.professionalId != null && appt.professionalId!.isNotEmpty) {
        try {
          // ignore: use_build_context_synchronously
          final repo = Provider.of<UserRepository>(context, listen: false);
          final professional = await repo.getUserById(appt.professionalId!);
          if (professional != null && professional.specialty.isNotEmpty) {
            resolvedCategory = professional.specialty;
          }
        } catch (_) {
          // keep resolved category
        }
      }

      if (!mounted) return;
      setState(() {
        _rescheduleAppointment = appt;
        _selectedService = Service(name: appt.service);
        _selectedDate = appt.dateTime;
        _startTime = TimeOfDay.fromDateTime(appt.dateTime);
        _category = resolvedCategory;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => _error = 'Failed to load appointment details');
    } finally {
      if (mounted) setState(() => _loadingAppointment = false);
    }
    await _loadProfessionals();
  }

  Future<void> _loadProfessionals() async {
    final repo = Provider.of<UserRepository>(context, listen: false);
    try {
      List<User> professionals;

      if (_isReschedule && _rescheduleAppointment?.professionalId != null) {
        try {
          final professional = await repo.getUserById(_rescheduleAppointment!.professionalId!);
          if (professional != null) {
            if (professional.specialty.isNotEmpty) {
              _category = professional.specialty;
            }
            professionals = await repo.getProfessionalsBySpecialty(_category);
          } else {
            professionals = await repo.getProfessionalsBySpecialty(_category);
          }
        } catch (_) {
          professionals = await repo.getProfessionalsBySpecialty(_category);
        }
      } else {
        professionals = await repo.getProfessionalsBySpecialty(_category);
      }

      if (!mounted) return;
      setState(() {
        _professionals = professionals;
        _loadingProfessionals = false;
        if (professionals.length == 1) {
          _selectedProfessional = professionals.first;
        } else if (_isReschedule && _rescheduleAppointment?.professionalId != null) {
          final matched = professionals.where(
            (p) => p.id == _rescheduleAppointment!.professionalId,
          ).toList();
          if (matched.length == 1) {
            _selectedProfessional = matched.first;
          } else {
            _selectedProfessional = null;
          }
        } else {
          _selectedProfessional = null;
        }
        if (!_isReschedule) {
          _startTime = null;
        }
        _dayAppointments = [];
        _rangeError = null;
      });
      if (_selectedProfessional != null) {
        _loadDayAppointments(_selectedProfessional!);
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

  List<Service> _servicesForDisplay(List<Service> services) {
    if (_selectedProfessional?.id != null) {
      final professionalServices = services
          .where((s) => s.isOfferedBy(_selectedProfessional!.id!))
          .toList();
      if (professionalServices.isNotEmpty) {
        return professionalServices;
      }
      final matched = ServiceProvider.defaultServices
          .where((s) => s.name == _category)
          .toList();
      if (matched.isNotEmpty) return matched;
      if (_selectedService != null) {
        final nameMatch = ServiceProvider.defaultServices
            .where((s) =>
                _selectedService!.name == s.name ||
                _selectedService!.name.startsWith('${s.name} \u2014 ') ||
                s.name.startsWith('${_selectedService!.name} \u2014 '))
            .toList();
        if (nameMatch.isNotEmpty) return nameMatch;
        return [_selectedService!];
      }
      return matched;
    }
    final source = services.isEmpty ? ServiceProvider.defaultServices : services;
    return source
        .where((s) => s.assignedProfessionalIds.isEmpty)
        .toList();
  }

  Service? _initialService(List<Service> filtered) {
    if (filtered.isEmpty) return null;
    if (widget.service != null && widget.service!.isNotEmpty) {
      final matched = filtered.firstWhere(
        (s) => s.name == widget.service || widget.service!.startsWith('${s.name} — '),
        orElse: () => filtered.first,
      );
      return matched;
    }
    return filtered.first;
  }

  List<Widget> _buildServiceCards(BuildContext context, List<Service> services) {
    final loc = AppLocalizations.of(context);
    final theme = Theme.of(context);

    return services.map((service) {
      final isSelected = _selectedService?.id == service.id;
      return Card(
        margin: const EdgeInsets.only(bottom: 8),
        color: isSelected ? theme.colorScheme.primaryContainer : null,
        elevation: isSelected ? 2 : 1,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: BorderSide(
            color: isSelected ? theme.colorScheme.primary : theme.colorScheme.outlineVariant,
            width: isSelected ? 2 : 1,
          ),
        ),
        child: InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: () {
            setState(() => _selectedService = service);
            if (_selectedProfessional != null) {
              _recalculateEndTime(_selectedProfessional!);
            }
          },
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        service.name,
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w700,
                          color: isSelected ? theme.colorScheme.onPrimaryContainer : null,
                        ),
                      ),
                    ),
                    if (isSelected)
                      Icon(Icons.check_circle, color: theme.colorScheme.primary),
                  ],
                ),
                if (service.description != null && service.description!.isNotEmpty) ...[
                  const SizedBox(height: 6),
                  Text(
                    service.description!,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: isSelected ? theme.colorScheme.onPrimaryContainer : null,
                    ),
                  ),
                ],
                const SizedBox(height: 10),
                Wrap(
                  spacing: 16,
                  runSpacing: 8,
                  children: [
                    if (service.durationMinutes != null)
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.timer_outlined, size: 16, color: theme.colorScheme.primary),
                          const SizedBox(width: 4),
                          Text(
                            '${service.durationMinutes} ${loc?.mins ?? 'min'}',
                            style: const TextStyle(fontWeight: FontWeight.w600),
                          ),
                        ],
                      ),
                    if (service.price != null)
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.payments_outlined, size: 16, color: theme.colorScheme.primary),
                          const SizedBox(width: 4),
                          Text(
                            FormatHelper.formatCurrency(service.price!),
                            style: const TextStyle(fontWeight: FontWeight.w700),
                          ),
                        ],
                      ),
                  ],
                ),
              ],
            ),
          ),
        ),
      );
    }).toList();
  }

  bool _servicesMatch(Service a, Service b) {
    if (a.id != null && b.id != null) return a.id == b.id;
    return a.name == b.name ||
        a.name.startsWith('${b.name} \u2014 ') ||
        b.name.startsWith('${a.name} \u2014 ');
  }

  Widget _buildServiceChooser(BuildContext context) {
    final auth = Provider.of<AuthProvider>(context, listen: false);
    final businessId = auth.currentUser?.businessId;
    final serviceProvider = Provider.of<ServiceProvider>(context, listen: false);

    return StreamBuilder<List<Service>>(
      stream: serviceProvider.streamServices(businessId: businessId),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting && !snapshot.hasData) {
          return const Center(
            child: Padding(
              padding: EdgeInsets.all(12),
              child: CircularProgressIndicator(),
            ),
          );
        }

        final services = snapshot.data ?? [];
        final displayServices = _servicesForDisplay(services);

        final isCurrentValid = _selectedService != null &&
            displayServices.any((s) => _servicesMatch(s, _selectedService!));
        if (_selectedProfessional != null && !isCurrentValid) {
          final initial = _initialService(displayServices);
          if (initial != null) {
            WidgetsBinding.instance.addPostFrameCallback((_) {
              if (mounted) setState(() => _selectedService = initial);
            });
          }
        }

        if (displayServices.isEmpty && _selectedService == null) {
          return Padding(
            padding: const EdgeInsets.symmetric(vertical: 8),
            child: Text(
              AppLocalizations.of(context)?.noServicesAvailable ?? 'No services available',
              style: TextStyle(color: Theme.of(context).colorScheme.onSurfaceVariant),
            ),
          );
        }

        final servicesToShow = displayServices.isEmpty && _selectedService != null
            ? [_selectedService!]
            : displayServices;

        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: _buildServiceCards(context, servicesToShow),
        );
      },
    );
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
        _startTime = null;
        _endTime = null;
        _rangeError = null;
      });
      if (_selectedProfessional != null) {
        _loadDayAppointments(_selectedProfessional!);
      }
    }
  }

  DateTime _combine(DateTime d, TimeOfDay t) {
    return DateTime(d.year, d.month, d.day, t.hour, t.minute);
  }

  int _selectedDurationMinutes(User professional) {
    return _selectedService?.durationMinutes ?? professional.slotDurationMinutes;
  }

  void _recalculateEndTime(User professional) {
    if (_startTime == null) {
      setState(() => _endTime = null);
      return;
    }
    final duration = _selectedDurationMinutes(professional);
    setState(() {
      _endTime = ScheduleHelper.computeEndTime(
        start: _startTime!,
        durationMinutes: duration,
      );
    });
    _validateSelection(professional);
  }

  void _validateSelection(User professional) {
    if (_selectedDate == null || _startTime == null) {
      setState(() => _rangeError = null);
      return;
    }

    final start = _combine(_selectedDate!, _startTime!);
    final duration = _selectedDurationMinutes(professional);

    final available = ScheduleHelper.isRangeAvailable(
      start: start,
      durationMinutes: duration,
      workStart: professional.workStart,
      workEnd: professional.workEnd,
      appointments: _dayAppointments,
      professionalId: professional.id!,
      bufferTimeMinutes: professional.bufferTimeMinutes,
      breakStart: professional.breakStart,
      breakEnd: professional.breakEnd,
    );

    setState(() {
      _rangeError = available
          ? null
          : 'Selected time conflicts with another appointment or working hours';
    });
  }

  Widget _buildTimeBanner(User professional) {
    final duration = _selectedDurationMinutes(professional);
    final isConflict = _rangeError != null;
    return Card(
      color: isConflict
          ? Theme.of(context).colorScheme.errorContainer.withValues(alpha: 0.3)
          : Theme.of(context)
              .colorScheme
              .secondaryContainer
              .withValues(alpha: 0.3),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          children: [
            Icon(
              isConflict ? Icons.warning_amber_rounded : Icons.schedule,
              color: isConflict
                  ? Theme.of(context).colorScheme.error
                  : Theme.of(context).colorScheme.onSecondaryContainer,
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                'Selected: ${_startTime!.format(context)} - ${_endTime!.format(context)} ($duration min)',
                style: Theme.of(context).textTheme.titleSmall?.copyWith(
                      color: isConflict
                          ? Theme.of(context).colorScheme.error
                          : Theme.of(context).colorScheme.onSecondaryContainer,
                      fontWeight: FontWeight.w600,
                    ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _loadDayAppointments(User professional) async {
    if (_selectedDate == null) {
      setState(() => _dayAppointments = []);
      return;
    }

    try {
      final repo = Provider.of<AppointmentProvider>(context, listen: false).repository;
      final allAppointments = await repo.getAppointmentsForProfessional(professional.id!, professionalEmail: professional.email);

      final dateStr = _selectedDate!;
      final dayAppointments = allAppointments.where((a) {
        return a.dateTime.year == dateStr.year &&
            a.dateTime.month == dateStr.month &&
            a.dateTime.day == dateStr.day &&
            !a.isTerminal &&
            !(_isReschedule && a.id == widget.appointmentId);
      }).toList();

      if (mounted) {
        setState(() => _dayAppointments = dayAppointments);
        _validateSelection(professional);
      }
    } catch (e) {
      // Keep existing appointments on error;
      // the final check before booking still protects against double booking.
    }
  }

  @override
  Widget build(BuildContext context) {
    final apptProvider = Provider.of<AppointmentProvider>(context);
    final auth = Provider.of<AuthProvider>(context, listen: false);
    final professional = _selectedProfessional;

    final loc = AppLocalizations.of(context);
    final serviceSubtype = _serviceSubtype(widget.service ?? '');
    final title = _category.isNotEmpty && serviceSubtype.isNotEmpty
        ? '${loc?.bookNow ?? 'Book Now'} $_category — $serviceSubtype'
        : _category.isNotEmpty
            ? '${loc?.bookNow ?? 'Book Now'} $_category'
            : '${loc?.bookNow ?? 'Book Now'} ${serviceSubtype.isNotEmpty ? serviceSubtype : ''}';

    return Scaffold(
      appBar: AppBar(
        title: Text(title),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const TenantBrandHeader(),
            const SizedBox(height: 12),
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
            if (_loadingAppointment || _loadingProfessionals)
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
                        _startTime = null;
                        _endTime = null;
                        _rangeError = null;
                        _dayAppointments = [];
                        if (value == null) _selectedService = null;
                      });
                  if (value != null) {
                    _loadDayAppointments(value);
                  }
                },
              ),
            const SizedBox(height: 12),
            Text(
              AppLocalizations.of(context)?.selectService ?? 'Select service',
              style: Theme.of(context).textTheme.titleSmall,
            ),
            const SizedBox(height: 8),
            if (_selectedProfessional == null)
              Card(
                color: Theme.of(context).colorScheme.surfaceContainerHighest,
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Row(
                    children: [
                      Icon(Icons.info_outline, color: Theme.of(context).colorScheme.primary),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'Select a staff member to see their offered services, or choose from the business-wide services below.',
                          style: Theme.of(context).textTheme.bodyMedium,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            const SizedBox(height: 8),
            _buildServiceChooser(context),
            if (_selectedService != null) ...[
              const SizedBox(height: 12),
              Card(
                color: Theme.of(context).colorScheme.secondaryContainer.withValues(alpha: 0.3),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _selectedService!.name,
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                              color: Theme.of(context).colorScheme.onSecondaryContainer,
                              fontWeight: FontWeight.w700,
                            ),
                      ),
                      if (_selectedService!.description != null &&
                          _selectedService!.description!.isNotEmpty) ...[
                        const SizedBox(height: 8),
                        Text(
                          _selectedService!.description!,
                          style: TextStyle(
                            color: Theme.of(context).colorScheme.onSecondaryContainer,
                            fontSize: 14,
                          ),
                        ),
                      ],
                      const SizedBox(height: 8),
                      Wrap(
                        spacing: 16,
                        runSpacing: 8,
                        children: [
                          if (_selectedService!.durationMinutes != null) ...[
                            Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(Icons.timer_outlined, size: 16, color: Theme.of(context).colorScheme.onSecondaryContainer),
                                const SizedBox(width: 4),
                                Text(
                                  '${_selectedService!.durationMinutes} ${AppLocalizations.of(context)?.mins ?? 'min'}',
                                  style: TextStyle(
                                    color: Theme.of(context).colorScheme.onSecondaryContainer,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ],
                            ),
                          ],
                          if (_selectedService!.price != null) ...[
                            Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(Icons.payments_outlined, size: 16, color: Theme.of(context).colorScheme.onSecondaryContainer),
                                const SizedBox(width: 4),
                                Text(
                                  FormatHelper.formatCurrency(_selectedService!.price!),
                                  style: TextStyle(
                                    color: Theme.of(context).colorScheme.onSecondaryContainer,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ],
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
                'Start time',
                style: Theme.of(context).textTheme.titleSmall,
              ),
              const SizedBox(height: 8),
              DropdownButtonFormField<TimeOfDay>(
                isExpanded: true,
                decoration: const InputDecoration(
                  labelText: 'Start time',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.access_time),
                ),
                value: _startTime,
                items: ScheduleHelper.generateStartTimes(
                  workStart: professional.workStart,
                  workEnd: professional.workEnd,
                ).map((t) {
                  return DropdownMenuItem(
                    value: t,
                    child: Text(t.format(context)),
                  );
                }).toList(),
                onChanged: (t) {
                  setState(() => _startTime = t);
                  _recalculateEndTime(professional);
                },
              ),
              const SizedBox(height: 12),
              if (_startTime != null && _endTime != null)
                _buildTimeBanner(professional),
              if (_rangeError != null)
                Padding(
                  padding: const EdgeInsets.only(top: 8),
                  child: Text(
                    _rangeError!,
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.error,
                    ),
                  ),
                ),
            ],
            const SizedBox(height: 20),
            if (_error != null)
              Text(_error!, style: const TextStyle(color: Colors.red)),
            const SizedBox(height: 12),
            ElevatedButton(
              onPressed: _loading ||
                      _loadingProfessionals ||
                      _professionals.isEmpty ||
                      _rangeError != null ||
                      _startTime == null
                  ? null
                  : () async {
                      if (_selectedProfessional == null) {
                        setState(() => _error = AppLocalizations.of(context)?.selectCustomer ?? 'Please select a professional');
                        return;
                      }

                      if (_selectedDate == null || _startTime == null) {
                        setState(() => _error = AppLocalizations.of(context)?.selectDate ?? 'Please select a date and time slot');
                        return;
                      }

                      final pro = _selectedProfessional!;
                      final duration = _selectedDurationMinutes(pro);
                      final dateTime = _combine(_selectedDate!, _startTime!);

                      final navigator = Navigator.of(context);
                      final scaffoldMessenger = ScaffoldMessenger.of(context);
                      final errorColor = Theme.of(context).colorScheme.error;

                      if (_rangeError != null) {
                        setState(() => _error = _rangeError);
                        return;
                      }

                      if (!await apptProvider.isSlotAvailable(
                        slotStart: dateTime,
                        slotDuration: duration,
                        professionalId: pro.id!,
                        bufferTimeMinutes: pro.bufferTimeMinutes,
                        professionalEmail: pro.email,
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
                      final selectedService = _selectedService;
                      final newAppt = Appointment(
                        serviceId: selectedService?.id,
                        service: selectedService?.name ?? widget.service ?? _category,
                        dateTime: dateTime,
                        durationMinutes: selectedService?.durationMinutes ?? pro.slotDurationMinutes,
                        price: selectedService?.price,
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

                      // ignore: use_build_context_synchronously
                      final l10n = AppLocalizations.of(context);

                      try {
                        if (_isReschedule && widget.appointmentId != null) {
                          final updated = Appointment(
                            id: widget.appointmentId,
                            serviceId: selectedService?.id,
                            service: selectedService?.name ?? widget.service ?? _category,
                            dateTime: dateTime,
                            durationMinutes: selectedService?.durationMinutes ?? pro.slotDurationMinutes,
                            price: selectedService?.price,
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
                          await apptProvider.rescheduleAppointment(
                            appointment: updated,
                            newDateTime: dateTime,
                          );
                          if (!mounted) return;
                          scaffoldMessenger
                            ..clearSnackBars()
                            ..showSnackBar(SnackBar(
                              content: Text(l10n?.bookingRescheduled ?? 'Booking rescheduled successfully'),
                            ));
                          navigator.pop(true);
                        } else {
                          await apptProvider.addAppointment(newAppt);

                          if (!mounted) return;

                          navigator.pushNamedAndRemoveUntil(
                            Routes.success,
                            (route) => false,
                            arguments: BookingSummary(
                              serviceId: selectedService?.id,
                              service: selectedService?.name ?? widget.service ?? _category,
                              price: selectedService?.price,
                              professionalName: pro.name,
                              professionalId: pro.id,
                              dateTime: dateTime,
                              durationMinutes: selectedService?.durationMinutes ?? pro.slotDurationMinutes,
                              customerName: customer.name,
                              customerPhone: customer.phone,
                              professionalPhone: pro.phone,
                              professionalEmail: pro.email,
                            ),
                          );
                        }
                      } catch (e) {
                        if (mounted) {
                          final displayError = apptProvider.errorMessage ?? ErrorHandler.getDisplayMessage(e);
                          scaffoldMessenger
                            ..clearSnackBars()
                            ..showSnackBar(SnackBar(
                              content: Text(displayError),
                              backgroundColor: errorColor,
                            ));
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
