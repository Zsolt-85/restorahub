import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../constants/constants.dart';
import '../exceptions/app_exception.dart';
import '../helpers/schedule_helper.dart';
import '../l10n/app_localizations.dart';
import '../models/appointment.dart';
import '../models/user.dart';
import '../providers/appointment_provider.dart';
import '../providers/auth_provider.dart';
import '../repositories/user_repository.dart';

class ProfessionalManualBookingPage extends StatefulWidget {
  const ProfessionalManualBookingPage({super.key});

  @override
  State<ProfessionalManualBookingPage> createState() =>
      _ProfessionalManualBookingPageState();
}

class _ProfessionalManualBookingPageState
    extends State<ProfessionalManualBookingPage> {
  final _formKey = GlobalKey<FormState>();
  final _customerSearchController = TextEditingController();
  final _searchController = TextEditingController();

  List<User> _customers = [];
  List<User> _filteredCustomers = [];
  User? _selectedCustomer;
  String? _selectedService;
  DateTime? _selectedDate;
  TimeOfDay? _selectedTime;
  bool _isLoading = false;
  String? _errorMessage;

  final Set<TimeOfDay> _unavailableSlots = {};

  StateSetter? _sheetSetState;

  @override
  void initState() {
    super.initState();
    _loadCustomers();
  }

  @override
  void dispose() {
    _customerSearchController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadCustomers() async {
    setState(() => _isLoading = true);
    try {
      final repo = context.read<UserRepository>();
      final customers = await repo.getCustomers();
      setState(() {
        _customers = customers;
        _filteredCustomers = customers;
      });
    } catch (e) {
      setState(() => _errorMessage = AppLocalizations.of(context)?.failedToLoadCustomers ?? 'Failed to load customers');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  void _filterCustomers(String query) {
    final lower = query.toLowerCase();
    setState(() {
      _filteredCustomers = _customers.where((c) {
        final name = c.name.toLowerCase();
        final email = c.email.toLowerCase();
        final phone = c.phone.toLowerCase();
        return name.contains(lower) || email.contains(lower) || phone.contains(lower);
      }).toList();
    });
    _sheetSetState?.call(() {});
  }

  void _clearCustomer() {
    setState(() {
      _selectedCustomer = null;
      _customerSearchController.clear();
    });
  }

  Widget _buildCustomerPreviewCard(User customer) {
    return Card(
      elevation: 2,
      child: ListTile(
        leading: const CircleAvatar(child: Icon(Icons.person)),
        title: Text(
          customer.name,
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
          subtitle: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(customer.phone.isNotEmpty ? customer.phone : AppLocalizations.of(context)?.noPhone ?? 'No phone'),
              Text(customer.email),
            ],
          ),
          trailing: IconButton(
            icon: const Icon(Icons.clear, color: Colors.red),
            tooltip: AppLocalizations.of(context)?.changeCustomer ?? 'Change customer',
            onPressed: _clearCustomer,
          ),
      ),
    );
  }

  List<String> _availableServices(User professional) {
    if (professional.specialty.isEmpty) return const [];
    return serviceNames
        .where(
          (s) =>
              ScheduleHelper.parseServiceCategory(s) ==
              professional.specialty,
        )
        .toList();
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
      final repo =
          Provider.of<AppointmentProvider>(context, listen: false).repository;
      final allAppointments =
          await repo.getAppointmentsForProfessional(professional.id!);

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

  Future<void> _pickDate() async {
    final professional = context.read<AuthProvider>().currentUser;
    if (professional == null) return;

    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate ?? now,
      firstDate: now,
      lastDate: now.add(const Duration(days: 90)),
    );
    if (picked != null) {
      setState(() {
        _selectedDate = picked;
        _selectedTime = null;
        _unavailableSlots.clear();
      });
      _loadSlotAvailability(professional);
    }
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    if (_selectedCustomer == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(AppLocalizations.of(context)?.pleaseSelectCustomer ?? 'Please select a customer')),
      );
      return;
    }
    if (_selectedService == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(AppLocalizations.of(context)?.pleaseSelectService ?? 'Please select a service')),
      );
      return;
    }
    if (_selectedDate == null || _selectedTime == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(AppLocalizations.of(context)?.pleaseSelectDateTime ?? 'Please select date and time')),
      );
      return;
    }

    final auth = context.read<AuthProvider>();
    final apptProvider = context.read<AppointmentProvider>();
    final professional = auth.currentUser;

    if (professional == null || professional.id == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(AppLocalizations.of(context)?.mustBeProfessional ?? 'You must be logged in as a professional')),
      );
      return;
    }

    final dateTime = DateTime(
      _selectedDate!.year,
      _selectedDate!.month,
      _selectedDate!.day,
      _selectedTime!.hour,
      _selectedTime!.minute,
    );

    final newAppt = Appointment(
      service: _selectedService!,
      dateTime: dateTime,
      durationMinutes: professional.slotDurationMinutes,
      status: AppointmentStatus.confirmed,
      customerId: _selectedCustomer!.id,
      customerName: _selectedCustomer!.name,
      customerPhone: _selectedCustomer!.phone,
      customerEmail: _selectedCustomer!.email,
      professionalId: professional.id,
      professionalName: professional.name,
      professionalPhone: professional.phone,
      professionalEmail: professional.email,
    );

    setState(() => _isLoading = true);
    try {
      await apptProvider.addAppointment(newAppt);
      if (!mounted) return;
      if (apptProvider.errorMessage != null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(apptProvider.errorMessage!)),
        );
        return;
      }
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(AppLocalizations.of(context)?.manualBookingCreated ?? 'Manual booking created successfully')),
      );
      Navigator.pop(context);
    } on AppException catch (e) {
      if (!mounted) return;
      setState(() => _errorMessage = e.message);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.message)),
      );
    } catch (e) {
      if (!mounted) return;
      setState(() => _errorMessage = AppLocalizations.of(context)?.bookingFailed ?? 'Failed to create booking');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(AppLocalizations.of(context)?.bookingFailed ?? 'Failed to create booking')),
      );
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final professional = auth.currentUser;

    if (professional == null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        Navigator.pushNamedAndRemoveUntil(context, '/login', (_) => false);
      });
      return const Scaffold(body: SizedBox.shrink());
    }

    final availableServices = _availableServices(professional);
    final timeSlots = _slotsForProfessional(professional);

    return Scaffold(
      appBar: AppBar(
        title: Text(AppLocalizations.of(context)?.createManualBooking ?? 'Create Manual Booking'),
      ),
      body: _isLoading && _customers.isEmpty
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    if (_errorMessage != null)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 12),
                        child: Text(
                          _errorMessage!,
                          style: TextStyle(
                            color: Theme.of(context).colorScheme.error,
                          ),
                        ),
                      ),
                     TextFormField(
                      readOnly: true,
                      decoration: InputDecoration(
                        labelText: AppLocalizations.of(context)?.selectCustomer ?? 'Select Customer',
                        border: const OutlineInputBorder(),
                      ),
                      controller: _customerSearchController,
                      onTap: () => _showCustomerPicker(),
                      validator: (_) =>
                          _selectedCustomer == null ? AppLocalizations.of(context)?.pleaseSelectCustomer ?? 'Select a customer' : null,
                    ),
                    if (_selectedCustomer != null)
                      _buildCustomerPreviewCard(_selectedCustomer!),
                    const SizedBox(height: 16),
                     DropdownButtonFormField<String>(
                      decoration: InputDecoration(
                        labelText: AppLocalizations.of(context)?.selectService ?? 'Select Service',
                        border: const OutlineInputBorder(),
                        errorText: availableServices.isEmpty
                            ? AppLocalizations.of(context)?.noServicesForSpecialty ?? 'No services for your specialty'
                            : null,
                      ),
                      items: availableServices
                          .map((s) => DropdownMenuItem(value: s, child: Text(s)))
                          .toList(),
                      initialValue: _selectedService,
                      validator: (_) =>
                          _selectedService == null ? AppLocalizations.of(context)?.pleaseSelectService ?? 'Select a service' : null,
                      onChanged: availableServices.isEmpty
                          ? null
                          : (v) => setState(() => _selectedService = v),
                    ),
                    const SizedBox(height: 16),
                     ListTile(
                      title: Text(
                        _selectedDate == null
                            ? AppLocalizations.of(context)?.selectDate ?? 'Select Date'
                            : '${AppLocalizations.of(context)?.selectDate ?? 'Date'}: ${_selectedDate!.day}/${_selectedDate!.month}/${_selectedDate!.year}',
                      ),
                      trailing: const Icon(Icons.calendar_today),
                      onTap: _pickDate,
                      shape: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide: BorderSide(
                          color: Theme.of(context).colorScheme.outline,
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    if (_selectedDate != null) ...[
                        Text(
                         '${AppLocalizations.of(context)?.availableSlots ?? 'Available slots'} (${professional.slotDurationMinutes} ${AppLocalizations.of(context)?.minEach ?? 'min each'})',
                         style: Theme.of(context).textTheme.titleSmall,
                       ),
                      const SizedBox(height: 8),
                       if (timeSlots.isEmpty)
                         Text(AppLocalizations.of(context)?.noAvailableSlots ?? 'No slots fit this professional schedule.')
                      else
                        Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: timeSlots.map((slot) {
                            final isSelected = _selectedTime == slot;
                            final isUnavailable =
                                _unavailableSlots.contains(slot);

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
                                   AppLocalizations.of(context)?.booked ?? 'Booked',
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
                                          style: TextStyle(
                                            color: Theme.of(context)
                                                .colorScheme
                                                .onPrimary,
                                          ),
                                        )
                                      : Text(slot.format(context)),
                              selected: isSelected,
                              onSelected: isUnavailable
                                  ? null
                                  : (_) => setState(() => _selectedTime = slot),
                            );
                          }).toList(),
                        ),
                    ],
                    const SizedBox(height: 24),
                     ElevatedButton(
                      onPressed: _isLoading ? null : _submit,
                      child: _isLoading
                          ? const SizedBox(
                              height: 20,
                              width: 20,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                           : Text(AppLocalizations.of(context)?.createBooking ?? 'Create Booking'),
                    ),
                  ],
                ),
              ),
            ),
    );
  }

  void _showCustomerPicker() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
       builder: (ctx) => StatefulBuilder(
         builder: (sheetCtx, setSheetState) {
           _sheetSetState = setSheetState;
           return DraggableScrollableSheet(
        initialChildSize: 0.6,
        minChildSize: 0.4,
        maxChildSize: 0.9,
        expand: false,
        builder: (ctx, scrollController) => Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(16),
                child: TextField(
                 key: const Key('search_customers'),
                 controller: _searchController,
                 decoration: InputDecoration(
                  labelText: AppLocalizations.of(context)?.searchCustomer ?? 'Search customers',
                  border: const OutlineInputBorder(),
                  prefixIcon: const Icon(Icons.search),
                ),
                onChanged: _filterCustomers,
              ),
            ),
            Expanded(
              child: ListView.builder(
                controller: scrollController,
                padding: const EdgeInsets.symmetric(horizontal: 16),
                itemCount: _filteredCustomers.length,
                     itemBuilder: (ctx, i) {
                       final c = _filteredCustomers[i];
                       return ListTile(
                         title: Text(c.name),
                         subtitle: Text(c.phone.isNotEmpty ? c.phone : c.email),
                         onTap: () {
                            setState(() {
                              _selectedCustomer = c;
                              _customerSearchController.text = c.name;
                              _searchController.clear();
                            });
                           Navigator.pop(ctx);
                         },
                       );
                     },
              ),
            ),
          ],
        ),
      );
    },
      ),
    );
  }
}
