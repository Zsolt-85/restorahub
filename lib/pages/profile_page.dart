import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../constants/routes.dart';
import '../constants/constants.dart';
import '../models/user.dart';
import '../providers/appointment_provider.dart';
import '../providers/auth_provider.dart';
import '../utils/error_handler.dart';

class ProfilePage extends StatefulWidget {
  const ProfilePage({super.key});

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
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

  @override
  void initState() {
    super.initState();
    _loadUser();
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
      appBar: AppBar(title: const Text('Edit profile')),
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
              'Personal information',
              style: Theme.of(context).textTheme.titleSmall,
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _nameController,
              decoration: const InputDecoration(
                labelText: 'Full name',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.person_outline),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _emailController,
              decoration: const InputDecoration(
                labelText: 'Email',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.email_outlined),
              ),
              keyboardType: TextInputType.emailAddress,
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _phoneController,
              decoration: const InputDecoration(
                labelText: 'Phone',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.phone_outlined),
              ),
              keyboardType: TextInputType.phone,
            ),
            if (user.isProfessional) ...[
              const SizedBox(height: 24),
              Text(
                'Professional settings',
                style: Theme.of(context).textTheme.titleSmall,
              ),
              const SizedBox(height: 8),
              DropdownButtonFormField<String>(
                initialValue: _specialty,
                decoration: const InputDecoration(
                  labelText: 'Profession / specialty',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.work_outline),
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
                title: const Text('Work day starts'),
                subtitle: Text(_workStart?.format(context) ?? 'Not set'),
                trailing: const Icon(Icons.schedule),
                onTap: () => _pickTime(isStart: true),
              ),
              ListTile(
                contentPadding: EdgeInsets.zero,
                title: const Text('Work day ends'),
                subtitle: Text(_workEnd?.format(context) ?? 'Not set'),
                trailing: const Icon(Icons.schedule),
                onTap: () => _pickTime(isStart: false),
              ),
              const SizedBox(height: 8),
              DropdownButtonFormField<int>(
                initialValue: _slotDurationMinutes,
                decoration: const InputDecoration(
                  labelText: 'Appointment slot length',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.timelapse),
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
                decoration: const InputDecoration(
                  labelText: 'Buffer time between appointments',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.timer_outlined),
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
                title: const Text('Break start'),
                subtitle: Text(_breakStart?.format(context) ?? 'Not set'),
                trailing: const Icon(Icons.free_breakfast),
                onTap: () => _pickBreakTime(isStart: true),
              ),
              ListTile(
                contentPadding: EdgeInsets.zero,
                title: const Text('Break end'),
                subtitle: Text(_breakEnd?.format(context) ?? 'Not set'),
                trailing: const Icon(Icons.free_breakfast),
                onTap: () => _pickBreakTime(isStart: false),
              ),
            ],
            const SizedBox(height: 24),
            Text(
              'Change password (optional)',
              style: Theme.of(context).textTheme.titleSmall,
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _passwordController,
              decoration: const InputDecoration(
                labelText: 'New password',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.lock_outline),
              ),
              obscureText: true,
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _confirmPasswordController,
              decoration: const InputDecoration(
                labelText: 'Confirm new password',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.lock_outline),
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
                          const SnackBar(
                            content: Text('Profile updated successfully'),
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
                  : const Text('Save changes'),
            ),
          ],
        ),
      ),
    );
  }
}
