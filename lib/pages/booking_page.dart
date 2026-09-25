import 'package:flutter/foundation.dart';
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
import '../providers/business_provider.dart';
import '../providers/service_provider.dart';
import '../repositories/staff_directory_repository.dart';
import '../repositories/user_repository.dart';
import '../utils/app_logger.dart';
import '../utils/error_handler.dart';

class BookingPage extends StatefulWidget {
  final String? service;
  final String? category;
  final String? appointmentId;
  final String? businessId;

  const BookingPage({
    super.key,
    this.service,
    this.category,
    this.appointmentId,
    this.businessId,
  });

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
  String? _professionalsError;
  // Debug builds only: raw error for diagnostics, never shown in release.
  String? _professionalsDebugError;

  Service? _selectedService;

  bool _loading = false;
  bool _loadingAppointment = false;
  String? _error;
  String? _rangeError;

  List<Appointment> _dayAppointments = [];

  late String _category;
  bool get _isReschedule =>
      widget.appointmentId != null && widget.appointmentId!.isNotEmpty;
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

  /// Debug builds only: full causal chain (AppException wraps the cause).
  static String _debugChain(Object e) {
    final buffer = StringBuffer(e.toString());
    Object? cause = e is AppException ? e.cause : null;
    var depth = 0;
    while (cause != null && depth < 3) {
      buffer.write(' | caused by: $cause');
      cause = cause is AppException ? cause.cause : null;
      depth++;
    }
    return buffer.toString();
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
      final apptProvider =
          Provider.of<AppointmentProvider>(context, listen: false);
      final appt = await apptProvider.getAppointmentById(widget.appointmentId!);
      if (appt == null) {
        if (!mounted) return;
        setState(() => _error = 'Failed to load appointment details');
        return;
      }

      String resolvedCategory = _category;

      String baseService = appt.service;
      if (baseService.contains('\u2014')) {
        baseService = baseService.split('\u2014').first.trim();
      }
      resolvedCategory = ServiceProvider.getCategoryForService(baseService);

      if (appt.professionalId != null && appt.professionalId!.isNotEmpty) {
        try {
          // ignore: use_build_context_synchronously
          final repo = Provider.of<UserRepository>(context, listen: false);
          final professional = await repo.getUserById(appt.professionalId!);
          if (professional != null && professional.category.isNotEmpty) {
            resolvedCategory = professional.category;
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
    // Public staff directory: the users collection cannot be listed by
    // customers in Firestore rules, so discovery reads here.
    final repo = Provider.of<StaffDirectoryRepository>(context, listen: false);
    final businessId = widget.businessId;
    AppLogger.debug(
        '_loadProfessionals: businessId=$businessId, isReschedule=$_isReschedule, category=$_category');
    try {
      List<User> professionals;

      if (_isReschedule && _rescheduleAppointment?.professionalId != null) {
        final targetedId = _rescheduleAppointment!.professionalId!;
        if (businessId != null && businessId.isNotEmpty) {
          professionals = await repo.getStaff(businessId: businessId);
        } else {
          try {
            final professional = await repo.getEntryById(targetedId);
            if (professional != null) {
              if (professional.category.isNotEmpty) {
                _category = professional.category;
              }
              professionals = await repo.getStaff(
                  businessId: businessId, category: _category);
            } else {
              professionals = await repo.getStaff(
                  businessId: businessId, category: _category);
            }
          } catch (_) {
            professionals = await repo.getStaff(
                businessId: businessId, category: _category);
          }
        }
      } else {
        if (_category.isEmpty) {
          professionals = await repo.getStaff(businessId: businessId);
        } else {
          professionals =
              await repo.getStaff(businessId: businessId, category: _category);
        }
      }

      if (!mounted) return;
      setState(() {
        _professionals = professionals;
        _loadingProfessionals = false;
        _professionalsError = null;
        _professionalsDebugError = null;
        if (professionals.length == 1) {
          _selectedProfessional = professionals.first;
        } else if (_isReschedule &&
            _rescheduleAppointment?.professionalId != null) {
          final matched = professionals
              .where(
                (p) => p.id == _rescheduleAppointment!.professionalId,
              )
              .toList();
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
      AppLogger.debug(
          '_loadProfessionals: _professionals.length=${_professionals.length}, businessId=$businessId');
      if (_selectedProfessional != null) {
        _loadDayAppointments(_selectedProfessional!);
      }
    } on AppException catch (e) {
      AppLogger.error('BookingPage._loadProfessionals AppException: $e');
      if (!mounted) return;
      setState(() {
        _loadingProfessionals = false;
        _professionals = [];
        _professionalsError = ErrorHandler.getDisplayMessage(e);
        _professionalsDebugError = kDebugMode ? _debugChain(e) : null;
      });
    } catch (e) {
      AppLogger.error('BookingPage._loadProfessionals error: $e');
      if (!mounted) return;
      setState(() {
        _loadingProfessionals = false;
        _professionals = [];
        _professionalsError = ErrorHandler.getDisplayMessage(e);
        _professionalsDebugError = kDebugMode ? _debugChain(e) : null;
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
      if (_selectedService != null) {
        return [_selectedService!];
      }
      return services.where((s) => s.category == _category).toList();
    }
    return services.where((s) => s.assignedProfessionalIds.isEmpty).toList();
  }

  Service? _initialService(List<Service> filtered) {
    if (filtered.isEmpty) return null;
    if (widget.service != null && widget.service!.isNotEmpty) {
      final matched = filtered.firstWhere(
        (s) =>
            s.name == widget.service ||
            widget.service!.startsWith('${s.name} — '),
        orElse: () => filtered.first,
      );
      return matched;
    }
    return filtered.first;
  }

  List<Widget> _buildServiceCards(
      BuildContext context, List<Service> services) {
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
            color: isSelected
                ? theme.colorScheme.primary
                : theme.colorScheme.outlineVariant,
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
                          color: isSelected
                              ? theme.colorScheme.onPrimaryContainer
                              : null,
                        ),
                      ),
                    ),
                    if (isSelected)
                      Icon(Icons.check_circle,
                          color: theme.colorScheme.primary),
                  ],
                ),
                if (service.description != null &&
                    service.description!.isNotEmpty) ...[
                  const SizedBox(height: 6),
                  Text(
                    service.description!,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: isSelected
                          ? theme.colorScheme.onPrimaryContainer
                          : null,
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
                          Icon(Icons.timer_outlined,
                              size: 16, color: theme.colorScheme.primary),
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
                          Icon(Icons.payments_outlined,
                              size: 16, color: theme.colorScheme.primary),
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
    final serviceProvider =
        Provider.of<ServiceProvider>(context, listen: false);

    return StreamBuilder<List<Service>>(
      stream: serviceProvider.streamServices(businessId: businessId),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting &&
            !snapshot.hasData) {
          return const Center(
            child: Padding(
              padding: EdgeInsets.all(12),
              child: CircularProgressIndicator(),
            ),
          );
        }

        if (snapshot.hasError) {
          return Padding(
            padding: const EdgeInsets.symmetric(vertical: 8),
            child: Column(
              children: [
                Text(
                  ErrorHandler.getDisplayMessage(snapshot.error!),
                  style: TextStyle(color: Theme.of(context).colorScheme.error),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 8),
                FilledButton.tonal(
                  // Rebuild resubscribes (fresh stream per build) = retry.
                  onPressed: () => setState(() {}),
                  child: const Text('Retry'),
                ),
              ],
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
              AppLocalizations.of(context)?.noServicesAvailable ??
                  'No services available',
              style: TextStyle(
                  color: Theme.of(context).colorScheme.onSurfaceVariant),
            ),
          );
        }

        final servicesToShow =
            displayServices.isEmpty && _selectedService != null
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
    return _selectedService?.durationMinutes ??
        professional.slotDurationMinutes;
  }

  /// Deposit-due notice shown when the active business requires one.
  /// Read-only: collection stays offline until Phase 4 billing.
  Widget _buildDepositNotice(BuildContext context) {
    final settings = Provider.of<BusinessProvider>(context, listen: false)
        .currentBusiness
        ?.settings;
    if (settings == null || !settings.isDepositRequired) {
      return const SizedBox.shrink();
    }
    final percent = settings.effectiveDepositPercent;
    final percentLabel = percent.toStringAsFixed(percent % 1 == 0 ? 0 : 1);
    final price = _selectedService?.price;
    final l10n = AppLocalizations.of(context);
    final message = price != null
        ? l10n?.depositDueAmount(percentLabel,
                FormatHelper.formatCurrency(price * percent / 100)) ??
            'A $percentLabel% deposit will be due at payment time'
        : l10n?.depositDuePercent(percentLabel) ??
            'A $percentLabel% deposit will be due at payment time';
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Card(
        color: Theme.of(context)
            .colorScheme
            .tertiaryContainer
            .withValues(alpha: 0.4),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            children: [
              Icon(Icons.savings_outlined,
                  color: Theme.of(context).colorScheme.onTertiaryContainer),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  message,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: Theme.of(context)
                            .colorScheme
                            .onTertiaryContainer,
                      ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// Start times with conflicts, breaks, and out-of-hours overflow already
  /// removed — the dropdown never offers an unbookable slot.
  List<TimeOfDay> _availableStartTimes(User professional) {
    if (_selectedDate == null) return [];
    final duration = _selectedDurationMinutes(professional);
    return ScheduleHelper.generateStartTimes(
      workStart: professional.workStart,
      workEnd: professional.workEnd,
    ).where((t) {
      return ScheduleHelper.isRangeAvailable(
        start: _combine(_selectedDate!, t),
        durationMinutes: duration,
        workStart: professional.workStart,
        workEnd: professional.workEnd,
        appointments: _dayAppointments,
        professionalId: professional.id!,
        bufferTimeMinutes: professional.bufferTimeMinutes,
        breakStart: professional.breakStart,
        breakEnd: professional.breakEnd,
      );
    }).toList();
  }

  /// Explains a disabled Confirm button; null when booking can proceed.
  String? _confirmBlockerReason() {
    if (_loading || _loadingProfessionals) return null;
    if (_professionals.isEmpty) {
      return AppLocalizations.of(context)?.noStaffForCategory ??
          'No staff available for this category';
    }
    if (_selectedProfessional == null) {
      return AppLocalizations.of(context)?.selectStaffToContinue ??
          'Select a staff member to continue';
    }
    if (_selectedDate == null) {
      return AppLocalizations.of(context)?.pickDateToContinue ??
          'Pick a date to continue';
    }
    if (_startTime == null) {
      return AppLocalizations.of(context)?.pickTimeToContinue ??
          'Pick a start time to continue';
    }
    if (_rangeError != null) return _rangeError;
    return null;
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
      final repo =
          Provider.of<AppointmentProvider>(context, listen: false).repository;
      final allAppointments = await repo.getAppointmentsForProfessional(
        professional.id!,
        professionalEmail: professional.email,
        businessId: professional.businessId ?? widget.businessId,
      );

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
            // Show banner only when professionals are available
            if (_professionals.isNotEmpty) ...[
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
            ],
            if (_loadingAppointment || _loadingProfessionals)
              const Center(child: CircularProgressIndicator())
            else if (_professionals.isEmpty)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 24),
                child: Column(
                  children: [
                    Icon(
                      _professionalsError != null
                          ? Icons.error_outline
                          : Icons.calendar_today_outlined,
                      size: 48,
                      color: Theme.of(context)
                          .colorScheme
                          .onSurfaceVariant
                          .withValues(alpha: 0.3),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      _professionalsError ??
                          'Services coming soon for this provider',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color:
                                Theme.of(context).colorScheme.onSurfaceVariant,
                          ),
                      textAlign: TextAlign.center,
                    ),
                    if (kDebugMode && _professionalsDebugError != null) ...[
                      const SizedBox(height: 8),
                      SelectableText(
                        _professionalsDebugError!,
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: Theme.of(context).colorScheme.error,
                              fontFamily: 'monospace',
                            ),
                        textAlign: TextAlign.center,
                      ),
                    ],
                    if (_professionalsError != null) ...[
                      const SizedBox(height: 12),
                      FilledButton.tonal(
                        onPressed: () {
                          setState(() {
                            _loadingProfessionals = true;
                            _professionalsError = null;
                          });
                          _loadProfessionals();
                        },
                        child: const Text('Retry'),
                      ),
                    ] else ...[
                      const SizedBox(height: 12),
                      OutlinedButton(
                        onPressed: () => Navigator.pop(context),
                        child: Text(
                          AppLocalizations.of(context)?.browseOtherCategories ??
                              'Browse other categories',
                        ),
                      ),
                    ],
                  ],
                ),
              )
            else if (_professionals.length == 1)
              Card(
                child: ListTile(
                  leading: const Icon(Icons.person),
                  title: Text(
                    _selectedProfessional?.name ?? 'Staff Member',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  subtitle: _selectedProfessional != null
                      ? Text(
                          '${_selectedProfessional!.workStart.format(context)}\u2013${_selectedProfessional!.workEnd.format(context)} \u00b7 ${_selectedProfessional!.slotDurationMinutes} min slots',
                          style: Theme.of(context).textTheme.bodySmall,
                        )
                      : null,
                ),
              )
            else
              DropdownButtonFormField<User>(
                key: ValueKey(professional?.id),
                initialValue: _selectedProfessional,
                decoration: InputDecoration(
                  labelText: AppLocalizations.of(context)?.selectStaffMember ??
                      'Select Staff Member',
                  border: const OutlineInputBorder(),
                  prefixIcon: const Icon(Icons.person_search),
                ),
                hint: Text(
                  AppLocalizations.of(context)?.anyAvailable ?? 'Any available',
                ),
                items: [
                  DropdownMenuItem<User>(
                    value: null,
                    child: Text(
                      AppLocalizations.of(context)?.anyAvailable ??
                          'Any available',
                    ),
                  ),
                  ..._professionals
                      .map(
                        (pro) => DropdownMenuItem(
                          value: pro,
                          child: Text(
                            '${pro.name} · ${pro.workStart.format(context)}\u2013${pro.workEnd.format(context)} · ${pro.slotDurationMinutes} min slots',
                          ),
                        ),
                      )
                      .toList(),
                ],
                onChanged: (User? value) {
                  // "Any available" auto-assigns the first professional
                  // instead of erroring at confirm time.
                  final effective = value ??
                      (_professionals.isNotEmpty ? _professionals.first : null);
                  setState(() {
                    _selectedProfessional = effective;
                    _startTime = null;
                    _endTime = null;
                    _rangeError = null;
                    _dayAppointments = [];
                    if (effective == null) _selectedService = null;
                  });
                  if (effective != null) {
                    _loadDayAppointments(effective);
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
                      Icon(Icons.info_outline,
                          color: Theme.of(context).colorScheme.primary),
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
              _buildDepositNotice(context),
              Card(
                color: Theme.of(context)
                    .colorScheme
                    .secondaryContainer
                    .withValues(alpha: 0.3),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _selectedService!.name,
                        style:
                            Theme.of(context).textTheme.titleMedium?.copyWith(
                                  color: Theme.of(context)
                                      .colorScheme
                                      .onSecondaryContainer,
                                  fontWeight: FontWeight.w700,
                                ),
                      ),
                      if (_selectedService!.description != null &&
                          _selectedService!.description!.isNotEmpty) ...[
                        const SizedBox(height: 8),
                        Text(
                          _selectedService!.description!,
                          style: TextStyle(
                            color: Theme.of(context)
                                .colorScheme
                                .onSecondaryContainer,
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
                                Icon(Icons.timer_outlined,
                                    size: 16,
                                    color: Theme.of(context)
                                        .colorScheme
                                        .onSecondaryContainer),
                                const SizedBox(width: 4),
                                Text(
                                  '${_selectedService!.durationMinutes} ${AppLocalizations.of(context)?.mins ?? 'min'}',
                                  style: TextStyle(
                                    color: Theme.of(context)
                                        .colorScheme
                                        .onSecondaryContainer,
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
                                Icon(Icons.payments_outlined,
                                    size: 16,
                                    color: Theme.of(context)
                                        .colorScheme
                                        .onSecondaryContainer),
                                const SizedBox(width: 4),
                                Text(
                                  FormatHelper.formatCurrency(
                                      _selectedService!.price!),
                                  style: TextStyle(
                                    color: Theme.of(context)
                                        .colorScheme
                                        .onSecondaryContainer,
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
                      ? AppLocalizations.of(context)?.selectDate ??
                          'Tap to choose a date'
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
              Builder(builder: (context) {
                final availableStarts = _availableStartTimes(professional);
                if (availableStarts.isEmpty) {
                  return Padding(
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    child: Text(
                      AppLocalizations.of(context)?.fullyBookedPickAnother ??
                          'Fully booked for this day — pick another date',
                      style: TextStyle(
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
                    ),
                  );
                }
                return DropdownButtonFormField<TimeOfDay>(
                  isExpanded: true,
                  decoration: const InputDecoration(
                    labelText: 'Start time',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.access_time),
                  ),
                  initialValue:
                      availableStarts.contains(_startTime) ? _startTime : null,
                  items: availableStarts.map((t) {
                    return DropdownMenuItem(
                      value: t,
                      child: Text(t.format(context)),
                    );
                  }).toList(),
                  onChanged: (t) {
                    setState(() => _startTime = t);
                    _recalculateEndTime(professional);
                  },
                );
              }),
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
            Builder(builder: (context) {
              final blocked = _loading ||
                  _loadingProfessionals ||
                  _professionals.isEmpty ||
                  _rangeError != null ||
                  _startTime == null;
              final blockerReason = blocked ? _confirmBlockerReason() : null;
              return Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  ElevatedButton(
                    onPressed: blocked
                        ? null
                        : () async {
                            if (_selectedProfessional == null) {
                              setState(() => _error =
                                  AppLocalizations.of(context)
                                          ?.selectStaffMember ??
                                      'Please select a staff member');
                              return;
                            }

                            if (_selectedDate == null || _startTime == null) {
                              setState(() => _error =
                                  AppLocalizations.of(context)?.selectDate ??
                                      'Please select a date and time slot');
                              return;
                            }

                            final pro = _selectedProfessional!;
                            final duration = _selectedDurationMinutes(pro);
                            final dateTime =
                                _combine(_selectedDate!, _startTime!);

                            final navigator = Navigator.of(context);
                            final scaffoldMessenger =
                                ScaffoldMessenger.of(context);
                            final errorColor =
                                Theme.of(context).colorScheme.error;

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
                              businessId: pro.businessId ?? widget.businessId,
                            )) {
                              setState(() => _error = AppLocalizations.of(
                                          context)
                                      ?.confirmed ??
                                  'This slot was just booked. Pick another.');
                              return;
                            }

                            setState(() {
                              _loading = true;
                              _error = null;
                            });

                            final customer = auth.currentUser!;
                            final selectedService = _selectedService;
                            // Tenant scope is mandatory: without businessId the
                            // booking is invisible to every business-scoped query
                            // (admin lists, analytics, payment backfill).
                            final bookingBusinessId =
                                widget.businessId ?? customer.businessId;
                            final newAppt = Appointment(
                              serviceId: selectedService?.id,
                              service: selectedService?.name ??
                                  widget.service ??
                                  _category,
                              dateTime: dateTime,
                              durationMinutes:
                                  selectedService?.durationMinutes ??
                                      pro.slotDurationMinutes,
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
                              businessId: bookingBusinessId,
                            );

                            // ignore: use_build_context_synchronously
                            final l10n = AppLocalizations.of(context);

                            try {
                              if (_isReschedule &&
                                  widget.appointmentId != null) {
                                final updated = Appointment(
                                  id: widget.appointmentId,
                                  serviceId: selectedService?.id,
                                  service: selectedService?.name ??
                                      widget.service ??
                                      _category,
                                  dateTime: dateTime,
                                  durationMinutes:
                                      selectedService?.durationMinutes ??
                                          pro.slotDurationMinutes,
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
                                  // Preserve tenant scope across reschedules; fall
                                  // back to the current booking context if unknown.
                                  businessId:
                                      _rescheduleAppointment?.businessId ??
                                          bookingBusinessId,
                                );
                                await apptProvider.rescheduleAppointment(
                                  appointment: updated,
                                  newDateTime: dateTime,
                                );
                                if (!mounted) return;
                                scaffoldMessenger
                                  ..clearSnackBars()
                                  ..showSnackBar(SnackBar(
                                    content: Text(l10n?.bookingRescheduled ??
                                        'Booking rescheduled successfully'),
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
                                    service: selectedService?.name ??
                                        widget.service ??
                                        _category,
                                    price: selectedService?.price,
                                    professionalName: pro.name,
                                    professionalId: pro.id,
                                    dateTime: dateTime,
                                    durationMinutes:
                                        selectedService?.durationMinutes ??
                                            pro.slotDurationMinutes,
                                    customerName: customer.name,
                                    customerPhone: customer.phone,
                                    professionalPhone: pro.phone,
                                    professionalEmail: pro.email,
                                  ),
                                );
                              }
                            } catch (e) {
                              if (mounted) {
                                final displayError =
                                    apptProvider.errorMessage ??
                                        ErrorHandler.getDisplayMessage(e);
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
                        : Text(AppLocalizations.of(context)?.confirmBooking ??
                            'Confirm booking'),
                  ),
                  if (blockerReason != null) ...[
                    const SizedBox(height: 8),
                    Text(
                      blockerReason,
                      style: TextStyle(
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ],
              );
            }),
          ],
        ),
      ),
    );
  }
}
