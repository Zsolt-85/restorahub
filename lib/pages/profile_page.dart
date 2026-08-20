import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../constants/routes.dart';
import '../constants/constants.dart';
import '../l10n/app_localizations.dart';
import '../models/service.dart';
import '../models/user.dart';
import '../providers/appointment_provider.dart';
import '../providers/auth_provider.dart';
import '../providers/business_provider.dart';
import '../repositories/service_repository.dart';
import '../utils/error_handler.dart';

class ProfilePage extends StatefulWidget {
  const ProfilePage({super.key});

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  String? _specialty;
  TimeOfDay? _workStart;
  TimeOfDay? _workEnd;
  int? _slotDurationMinutes;
  int? _bufferTimeMinutes;
  TimeOfDay? _breakStart;
  TimeOfDay? _breakEnd;

  bool _loading = false;
  String? _error;

  List<Service> _businessServices = [];
  bool _loadingServices = false;

  @override
  void initState() {
    super.initState();
    _loadUser();
    if (Provider.of<AuthProvider>(context, listen: false).currentUser?.isProfessional ?? false) {
      WidgetsBinding.instance.addPostFrameCallback((_) => _loadBusinessServices());
    }
  }

  void _loadUser() {
    final user = Provider.of<AuthProvider>(context, listen: false).currentUser;
    if (user == null) return;

    _nameController.text = user.name;
    _emailController.text = user.email;
    _phoneController.text = user.phone;

    if (user.isProfessional) {
      _specialty = user.specialty.isEmpty ? serviceNames.first : user.specialty;
      _workStart = user.workStart;
      _workEnd = user.workEnd;
      _slotDurationMinutes = user.slotDurationMinutes;
      _bufferTimeMinutes = user.bufferTimeMinutes;
      _breakStart = user.breakStart;
      _breakEnd = user.breakEnd;
    }
  }

  Future<void> _loadBusinessServices() async {
    final auth = Provider.of<AuthProvider>(context, listen: false);
    final user = auth.currentUser;
    if (user == null || !user.isProfessional) return;

    final businessProvider = Provider.of<BusinessProvider>(context, listen: false);
    final businessId = businessProvider.currentBusiness?.id ?? user.businessId;
    if (businessId == null || businessId.isEmpty) return;

    setState(() => _loadingServices = true);
    try {
      final repository = Provider.of<ServiceRepository>(context, listen: false);
      final services = await repository.getServices(businessId: businessId);
      if (mounted) {
        setState(() => _businessServices = services);
      }
    } catch (e) {
      if (mounted) {
        setState(() => _businessServices = []);
      }
    } finally {
      if (mounted) {
        setState(() => _loadingServices = false);
      }
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  Future<void> _pickTime({required bool isStart}) async {
    final picked = await showTimePicker(
      context: context,
      initialTime: (isStart ? _workStart : _workEnd) ?? const TimeOfDay(hour: 9, minute: 0),
    );

    if (picked != null) {
      setState(() {
        if (isStart) {
          _workStart = picked;
        } else {
          _workEnd = picked;
        }
      });
    }
  }

  Future<void> _pickBreakTime({required bool isStart}) async {
    final picked = await showTimePicker(
      context: context,
      initialTime: (isStart ? _breakStart : _breakEnd) ?? const TimeOfDay(hour: 12, minute: 0),
    );

    if (picked != null) {
      setState(() {
        if (isStart) {
          _breakStart = picked;
        } else {
          _breakEnd = picked;
        }
      });
    }
  }

  Future<void> _createCustomService() async {
    final auth = Provider.of<AuthProvider>(context, listen: false);
    final user = auth.currentUser;
    if (user == null || !user.isProfessional || user.id == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('User not authenticated. Please log in again.'),
          backgroundColor: Theme.of(context).colorScheme.error,
        ),
      );
      return;
    }

    final businessProvider = Provider.of<BusinessProvider>(context, listen: false);
    final businessId = businessProvider.currentBusiness?.id ?? user.businessId;
    if (businessId == null || businessId.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('No business associated with your account. Please contact support.'),
          backgroundColor: Theme.of(context).colorScheme.error,
        ),
      );
      return;
    }

    final nameController = TextEditingController();
    final descriptionController = TextEditingController();
    final durationController = TextEditingController();
    final priceController = TextEditingController();
    final l10n = AppLocalizations.of(context);
    final errorColor = Theme.of(context).colorScheme.error;

    await showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(l10n?.addService ?? 'Add Service'),
        content: SingleChildScrollView(
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextFormField(
                  controller: nameController,
                  decoration: InputDecoration(
                    labelText: l10n?.name ?? 'Name',
                    border: const OutlineInputBorder(),
                  ),
                  textInputAction: TextInputAction.next,
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Service name is required';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: descriptionController,
                  decoration: InputDecoration(
                    labelText: l10n?.description ?? 'Description',
                    border: const OutlineInputBorder(),
                  ),
                  maxLines: 3,
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: durationController,
                  decoration: InputDecoration(
                    labelText: l10n?.durationMinutes ?? 'Duration (minutes)',
                    border: const OutlineInputBorder(),
                  ),
                  keyboardType: TextInputType.number,
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Duration is required';
                    }
                    final parsed = int.tryParse(value.trim());
                    if (parsed == null || parsed <= 0) {
                      return 'Enter a valid duration in minutes';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: priceController,
                  decoration: InputDecoration(
                    labelText: l10n?.price ?? 'Price',
                    border: const OutlineInputBorder(),
                  ),
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Price is required';
                    }
                    final parsed = double.tryParse(value.trim());
                    if (parsed == null || parsed < 0) {
                      return 'Enter a valid price';
                    }
                    return null;
                  },
                ),
              ],
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: Text(l10n?.cancel ?? 'Cancel'),
          ),
          TextButton(
            onPressed: () async {
              final messenger = ScaffoldMessenger.of(context);

              if (!_formKey.currentState!.validate()) {
                messenger.showSnackBar(
                  SnackBar(
                    content: const Text('Please correct the errors above'),
                    backgroundColor: errorColor,
                  ),
                );
                return;
              }

              final name = nameController.text.trim();
              final description = descriptionController.text.trim();
              final duration = int.tryParse(durationController.text.trim());
              final price = double.tryParse(priceController.text.trim());

              Navigator.pop(dialogContext);
              setState(() => _loading = true);

              try {
                final repository = Provider.of<ServiceRepository>(context, listen: false);
                final service = Service(
                  name: name,
                  description: description.isEmpty ? null : description,
                  businessId: businessId,
                  durationMinutes: duration,
                  price: price,
                  assignedProfessionalIds: [user.id!],
                );
                await repository.createService(service);
                if (!mounted) return;
                _formKey.currentState?.reset();
                nameController.clear();
                descriptionController.clear();
                durationController.clear();
                priceController.clear();
                messenger.showSnackBar(
                  SnackBar(content: Text(l10n?.save ?? 'Service created')),
                );
                await _loadBusinessServices();
              } catch (e) {
                if (!mounted) return;
                debugPrint('Error creating service: $e');
                final errorMessage = e is FirebaseException
                    ? (e.message ?? e.toString())
                    : e.toString();
                messenger.showSnackBar(
                  SnackBar(
                    content: Text(errorMessage),
                    backgroundColor: errorColor,
                  ),
                );
              } finally {
                if (mounted) {
                  setState(() => _loading = false);
                }
              }
            },
            child: Text(l10n?.save ?? 'Save'),
          ),
        ],
      ),
    );
  }

  Future<void> _toggleProfessionalAssignment(Service service) async {
    final auth = Provider.of<AuthProvider>(context, listen: false);
    final user = auth.currentUser;
    if (user == null || !user.isProfessional || user.id == null) return;

    final isAssigned = service.assignedProfessionalIds.contains(user.id);
    final updatedIds = List<String>.from(service.assignedProfessionalIds);
    if (isAssigned) {
      updatedIds.remove(user.id);
    } else {
      updatedIds.add(user.id!);
    }

    setState(() => _loading = true);
    try {
      final repository = Provider.of<ServiceRepository>(context, listen: false);
      final updatedService = service.copyWith(assignedProfessionalIds: updatedIds);
      await repository.updateService(updatedService);
      if (!mounted) return;
      await _loadBusinessServices();
    } catch (e) {
      if (!mounted) return;
      ErrorHandler.showErrorSnackBar(context, ErrorHandler.getDisplayMessage(e));
    } finally {
      if (mounted) {
        setState(() => _loading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final auth = Provider.of<AuthProvider>(context);
    final user = auth.currentUser;

    if (user == null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        Navigator.pushNamedAndRemoveUntil(context, Routes.login, (_) => false);
      });
      return const Scaffold(body: SizedBox.shrink());
    }

    return Scaffold(
      appBar: AppBar(title: Text(AppLocalizations.of(context)?.profile ?? 'Edit profile')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Card(
              child: ListTile(
                leading: CircleAvatar(
                  child: Text(user.name.substring(0, 1).toUpperCase()),
                ),
                title: Text(user.name),
                subtitle: Text(user.isProfessional
                    ? '${user.roleLabel} · ${user.specialty}'
                    : user.roleLabel),
                trailing: Chip(label: Text(user.roleLabel)),
              ),
            ),
            const SizedBox(height: 16),
            Text(
              AppLocalizations.of(context)?.customerDetails ?? 'Personal information',
              style: Theme.of(context).textTheme.titleSmall,
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _nameController,
              decoration: InputDecoration(
                labelText: AppLocalizations.of(context)?.name ?? 'Full name',
                border: const OutlineInputBorder(),
                prefixIcon: const Icon(Icons.person_outline),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _emailController,
              decoration: InputDecoration(
                labelText: AppLocalizations.of(context)?.email ?? 'Email',
                border: const OutlineInputBorder(),
                prefixIcon: const Icon(Icons.email_outlined),
              ),
              keyboardType: TextInputType.emailAddress,
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _phoneController,
              decoration: InputDecoration(
                labelText: AppLocalizations.of(context)?.phone ?? 'Phone',
                border: const OutlineInputBorder(),
                prefixIcon: const Icon(Icons.phone_outlined),
              ),
              keyboardType: TextInputType.phone,
            ),
            if (user.isProfessional) ...[
              const SizedBox(height: 24),
              Text(
                AppLocalizations.of(context)?.professionalSettings ?? 'Professional settings',
                style: Theme.of(context).textTheme.titleSmall,
              ),
              const SizedBox(height: 8),
               DropdownButtonFormField<String>(
                 initialValue: _specialty,
                 decoration: InputDecoration(
                   labelText: AppLocalizations.of(context)?.professionSpecialty ?? 'Profession / specialty',
                   border: const OutlineInputBorder(),
                   prefixIcon: const Icon(Icons.work_outline),
                 ),
                items: serviceNames
                    .map((name) => DropdownMenuItem(
                          value: name,
                          child: Text(name),
                        ))
                    .toList(),
                onChanged: (value) => setState(() => _specialty = value),
              ),
              const SizedBox(height: 12),
              ListTile(
                contentPadding: EdgeInsets.zero,
                title: Text(AppLocalizations.of(context)?.workDayStarts ?? 'Work day starts'),
                subtitle: Text(_workStart?.format(context) ?? AppLocalizations.of(context)?.notSet ?? 'Not set'),
                trailing: const Icon(Icons.schedule),
                onTap: () => _pickTime(isStart: true),
              ),
              ListTile(
                contentPadding: EdgeInsets.zero,
                title: Text(AppLocalizations.of(context)?.workDayEnds ?? 'Work day ends'),
                subtitle: Text(_workEnd?.format(context) ?? AppLocalizations.of(context)?.notSet ?? 'Not set'),
                trailing: const Icon(Icons.schedule),
                onTap: () => _pickTime(isStart: false),
              ),
              const SizedBox(height: 8),
               DropdownButtonFormField<int>(
                 initialValue: _slotDurationMinutes,
                 decoration: InputDecoration(
                   labelText: AppLocalizations.of(context)?.appointmentSlotLength ?? 'Appointment slot length',
                   border: const OutlineInputBorder(),
                   prefixIcon: const Icon(Icons.timelapse),
                 ),
                items: slotDurationOptions
                    .map(
                      (minutes) => DropdownMenuItem(
                        value: minutes,
                        child: Text('$minutes minutes'),
                      ),
                    )
                    .toList(),
                onChanged: (value) =>
                    setState(() => _slotDurationMinutes = value),
              ),
              const SizedBox(height: 12),
               DropdownButtonFormField<int>(
                 initialValue: _bufferTimeMinutes,
                 decoration: InputDecoration(
                   labelText: AppLocalizations.of(context)?.bufferTimeBetweenAppointments ?? 'Buffer time between appointments',
                   border: const OutlineInputBorder(),
                   prefixIcon: const Icon(Icons.timer_outlined),
                 ),
                items: bufferTimeOptions
                    .map(
                      (minutes) => DropdownMenuItem(
                        value: minutes,
                        child: Text('$minutes minutes'),
                      ),
                    )
                    .toList(),
                onChanged: (value) =>
                    setState(() => _bufferTimeMinutes = value),
              ),
              const SizedBox(height: 12),
              ListTile(
                contentPadding: EdgeInsets.zero,
                title: Text(AppLocalizations.of(context)?.breakStart ?? 'Break start'),
                subtitle: Text(_breakStart?.format(context) ?? AppLocalizations.of(context)?.notSet ?? 'Not set'),
                trailing: const Icon(Icons.free_breakfast),
                onTap: () => _pickBreakTime(isStart: true),
              ),
              ListTile(
                contentPadding: EdgeInsets.zero,
                title: Text(AppLocalizations.of(context)?.breakEnd ?? 'Break end'),
                subtitle: Text(_breakEnd?.format(context) ?? AppLocalizations.of(context)?.notSet ?? 'Not set'),
                trailing: const Icon(Icons.free_breakfast),
                onTap: () => _pickBreakTime(isStart: false),
              ),
              const SizedBox(height: 24),
              Text(
                AppLocalizations.of(context)?.myOfferedServices ?? 'My Offered Services',
                style: Theme.of(context).textTheme.titleSmall,
              ),
              const SizedBox(height: 8),
              if (_loadingServices)
                const Center(child: Padding(
                  padding: EdgeInsets.all(16),
                  child: CircularProgressIndicator(),
                )),
              if (_businessServices.isEmpty && !_loadingServices)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  child: Text(
                    AppLocalizations.of(context)?.noServicesAvailable ?? 'No services available',
                    style: TextStyle(color: Theme.of(context).colorScheme.onSurfaceVariant),
                  ),
                ),
              ..._businessServices.map((service) {
                final isAssigned = user.isProfessional && user.id != null
                    ? service.assignedProfessionalIds.contains(user.id)
                    : false;
                return Card(
                  margin: const EdgeInsets.only(bottom: 8),
                  child: ListTile(
                    title: Text(service.name),
                    subtitle: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        if (service.description != null && service.description!.isNotEmpty)
                          Text(service.description!),
                        if (service.durationMinutes != null || service.price != null)
                          Text(
                            [
                              if (service.durationMinutes != null) '${service.durationMinutes} min',
                               if (service.price != null) '${service.price!.toStringAsFixed(2)} RON',
                            ].join(' · '),
                          ),
                      ],
                    ),
                    trailing: Switch(
                      value: isAssigned,
                      onChanged: (_) => _toggleProfessionalAssignment(service),
                    ),
                  ),
                );
              }).toList(),
              ElevatedButton.icon(
                onPressed: _loading ? null : _createCustomService,
                icon: const Icon(Icons.add),
                label: Text(AppLocalizations.of(context)?.addService ?? 'Add Custom Service'),
              ),
            ],
            const SizedBox(height: 24),
            Text(
              AppLocalizations.of(context)?.changePassword ?? 'Change password (optional)',
              style: Theme.of(context).textTheme.titleSmall,
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _passwordController,
              decoration: InputDecoration(
                labelText: AppLocalizations.of(context)?.newPassword ?? 'New password',
                border: const OutlineInputBorder(),
                prefixIcon: const Icon(Icons.lock_outline),
              ),
              obscureText: true,
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _confirmPasswordController,
              decoration: InputDecoration(
                labelText: AppLocalizations.of(context)?.confirmNewPassword ?? 'Confirm new password',
                border: const OutlineInputBorder(),
                prefixIcon: const Icon(Icons.lock_outline),
              ),
              obscureText: true,
            ),
            const SizedBox(height: 20),
            if (_error != null)
              Text(_error!, style: const TextStyle(color: Colors.red)),
            const SizedBox(height: 12),
            ElevatedButton(
              onPressed: _loading
                  ? null
                  : () async {
                      setState(() {
                        _loading = true;
                        _error = null;
                      });

                      final result = await auth.updateProfile(
                        name: _nameController.text,
                        email: _emailController.text,
                        phone: _phoneController.text,
                        newPassword: _passwordController.text.trim().isEmpty
                            ? null
                            : _passwordController.text,
                        confirmPassword:
                            _confirmPasswordController.text.trim().isEmpty
                                ? null
                                : _confirmPasswordController.text,
                        specialty: user.isProfessional ? _specialty : null,
                        workStart: user.isProfessional ? _workStart : null,
                        workEnd: user.isProfessional ? _workEnd : null,
                        slotDurationMinutes:
                            user.isProfessional ? _slotDurationMinutes : null,
                        bufferTimeMinutes:
                            user.isProfessional ? _bufferTimeMinutes : null,
                        breakStartTime: user.isProfessional && _breakStart != null
                            ? User.formatTime(_breakStart!)
                            : null,
                        breakEndTime: user.isProfessional && _breakEnd != null
                            ? User.formatTime(_breakEnd!)
                            : null,
                      );

                      if (!context.mounted) return;

                      setState(() => _loading = false);

                      if (result == null) {
                        await Provider.of<AppointmentProvider>(context,
                                listen: false)
                            .loadAppointments();

                        if (!context.mounted) return;

                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(AppLocalizations.of(context)?.profileUpdatedSuccessfully ?? 'Profile updated successfully'),
                          ),
                        );
                        Navigator.pop(context);
                      } else {
                        setState(() => _error = ErrorHandler.getDisplayMessage(result));
                      }
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
                  : Text(AppLocalizations.of(context)?.save ?? 'Save changes'),
            ),
          ],
        ),
      ),
    );
  }
}
