import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../constants/constants.dart';
import '../helpers/validation_helper.dart';
import '../providers/appointment_provider.dart';
import '../providers/auth_provider.dart';

class RegistrationPage extends StatefulWidget {
  const RegistrationPage({super.key});

  @override
  State<RegistrationPage> createState() => _RegistrationPageState();
}

class _RegistrationPageState extends State<RegistrationPage> {
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();
  final _passwordController = TextEditingController();

  String _role = 'customer';
  String? _specialty;

  bool _loading = false;
  String? _error;

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _register() async {
    final nameError = ValidationHelper.validateName(_nameController.text);
    final emailError = ValidationHelper.validateEmail(_emailController.text);
    final phoneError = ValidationHelper.validatePhone(_phoneController.text);
    final passwordError =
        ValidationHelper.validatePassword(_passwordController.text.trim());

    var validationError =
        nameError ?? emailError ?? phoneError ?? passwordError;

    if (_role == 'professional' &&
        (_specialty == null || _specialty!.isEmpty)) {
      validationError = 'Please select your profession';
    }

    if (validationError != null) {
      setState(() => _error = validationError);
      return;
    }

    setState(() {
      _loading = true;
      _error = null;
    });

    final email = _emailController.text.trim();
    final password = _passwordController.text.trim();

    try {
      final auth = Provider.of<AuthProvider>(context, listen: false);

      final success = await auth.register(
        email: email,
        password: password,
        role: _role,
        name: _nameController.text.trim(),
        phone: _phoneController.text.trim(),
        specialty: _role == 'professional' ? _specialty! : '',
      );

      if (!mounted) return;

      setState(() => _loading = false);

      if (!mounted) return;

      if (success && auth.currentUser != null) {
        final appointmentProvider =
            Provider.of<AppointmentProvider>(context, listen: false);
        appointmentProvider.setCurrentUser(auth.currentUser!);

        Navigator.pushReplacementNamed(
          context,
          auth.currentUser!.isProfessional
              ? '/professional_home'
              : '/user_home',
        );
      } else {
        setState(() =>
            _error = 'Registration failed. Email may already be registered.');
      }
    } catch (e) {
      setState(() {
        _error = 'Registration failed: ${e.toString()}';
        _loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Register')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            TextField(
              controller: _nameController,
              decoration: const InputDecoration(
                labelText: 'Full name',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _emailController,
              decoration: const InputDecoration(
                labelText: 'Email',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _phoneController,
              decoration: const InputDecoration(
                labelText: 'Phone',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _passwordController,
              obscureText: true,
              decoration: const InputDecoration(
                labelText: 'Password',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),
            const Text('Account type'),
            SegmentedButton<String>(
              segments: const [
                ButtonSegment(value: 'customer', label: Text('Customer')),
                ButtonSegment(value: 'professional', label: Text('Professional')),
              ],
              selected: {_role},
              onSelectionChanged: (selection) {
                setState(() {
                  _role = selection.first;
                  _specialty =
                      _role == 'professional' ? serviceNames.first : null;
                });
              },
            ),
            if (_role == 'professional') ...[
              const SizedBox(height: 8),
              DropdownButtonFormField<String>(
                initialValue: _specialty,
                decoration: const InputDecoration(
                  labelText: 'Specialty',
                  border: OutlineInputBorder(),
                ),
                items: serviceNames
                    .map((e) => DropdownMenuItem(
                          value: e,
                          child: Text(e),
                        ))
                    .toList(),
                onChanged: (v) => setState(() => _specialty = v),
              ),
            ],
            const SizedBox(height: 12),
            if (_error != null)
              Text(
                _error!,
                style: const TextStyle(color: Colors.red),
              ),
            const SizedBox(height: 12),
            ElevatedButton(
              onPressed: _loading ? null : _register,
              child: _loading
                  ? const CircularProgressIndicator(color: Colors.white)
                  : const Text("Register"),
            ),
          ],
        ),
      ),
    );
  }
}
