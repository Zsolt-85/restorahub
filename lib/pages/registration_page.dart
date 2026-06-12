import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../constants/constants.dart';
import '../helpers/password_helper.dart';
import '../helpers/validation_helper.dart';
import '../models/user.dart';
import '../providers/appointment_provider.dart';
import '../providers/auth_provider.dart';
import '../repositories/local_booking_repository.dart';

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

  @override
  Widget build(BuildContext context) {
    final auth = Provider.of<AuthProvider>(context, listen: false);

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
                prefixIcon: Icon(Icons.person_outline),
              ),
              textCapitalization: TextCapitalization.words,
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
            const SizedBox(height: 12),
            TextField(
              controller: _passwordController,
              decoration: const InputDecoration(
                labelText: 'Password',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.lock_outline),
              ),
              obscureText: true,
            ),
            const SizedBox(height: 16),
            Text(
              'Account type',
              style: Theme.of(context).textTheme.titleSmall,
            ),
            Row(
              children: [
                Expanded(
                  child: RadioListTile<String>(
                    title: const Text('Customer'),
                    value: 'customer',
                    groupValue: _role,
                    onChanged: (value) {
                      if (value == null) return;
                      setState(() {
                        _role = value;
                        _specialty = null;
                      });
                    },
                  ),
                ),
                Expanded(
                  child: RadioListTile<String>(
                    title: const Text('Professional'),
                    value: 'professional',
                    groupValue: _role,
                    onChanged: (value) {
                      if (value == null) return;
                      setState(() {
                        _role = value;
                        _specialty ??= serviceNames.first;
                      });
                    },
                  ),
                ),
              ],
            ),
            if (_role == 'professional') ...[
              const SizedBox(height: 8),
              DropdownButtonFormField<String>(
                initialValue: _specialty,
                decoration: const InputDecoration(
                  labelText: 'Profession / specialty',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.work_outline),
                ),
                items: serviceNames
                    .map(
                      (name) => DropdownMenuItem(
                        value: name,
                        child: Text(name),
                      ),
                    )
                    .toList(),
                onChanged: (value) => setState(() => _specialty = value),
              ),
              const SizedBox(height: 8),
              Text(
                'You can set working hours and slot length in your profile after registration.',
                style: Theme.of(context).textTheme.bodySmall,
              ),
            ],
            const SizedBox(height: 12),
            if (_error != null)
              Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: Text(
                  _error!,
                  style: const TextStyle(color: Colors.red),
                ),
              ),
            ElevatedButton(
              onPressed: _loading
                  ? null
                  : () async {
                      final nameError =
                          ValidationHelper.validateName(_nameController.text);
                      final emailError =
                          ValidationHelper.validateEmail(_emailController.text);
                      final phoneError =
                          ValidationHelper.validatePhone(_phoneController.text);
                      final passwordError = ValidationHelper.validatePassword(
                        _passwordController.text.trim(),
                      );

                      var validationError = nameError ??
                          emailError ??
                          phoneError ??
                          passwordError;

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

                      final plainPassword = _passwordController.text.trim();
                      final email = _emailController.text.trim();
                      final repository = LocalBookingRepository.instance;

                      if (await repository.isEmailTaken(email)) {
                        setState(() {
                          _error = 'Email is already registered';
                          _loading = false;
                        });
                        return;
                      }

                      final newUser = User(
                        name: _nameController.text.trim(),
                        email: email,
                        phone: _phoneController.text.trim(),
                        password: PasswordHelper.hash(plainPassword),
                        role: _role,
                        specialty:
                            _role == 'professional' ? _specialty! : '',
                      );

                      try {
                        await repository.insertUser(newUser);
                      } catch (_) {
                        setState(() {
                          _error = 'Registration failed. Please try again.';
                          _loading = false;
                        });
                        return;
                      }

                      final success =
                          await auth.login(newUser.email, plainPassword);

                      if (!mounted) return;

                      setState(() => _loading = false);

                      if (success) {
                        Provider.of<AppointmentProvider>(context, listen: false)
                            .setCurrentUser(auth.currentUser!);

                        final route = newUser.isProfessional
                            ? '/professional_home'
                            : '/user_home';
                        Navigator.pushReplacementNamed(context, route);
                      } else {
                        setState(() => _error = 'Auto login failed');
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
                  : const Text('Register'),
            ),
          ],
        ),
      ),
    );
  }
}
