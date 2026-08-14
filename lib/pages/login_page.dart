import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../constants/routes.dart';
import '../constants/constants.dart';
import '../helpers/validation_helper.dart';
import '../providers/appointment_provider.dart';
import '../providers/auth_provider.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _loading = false;
  String? _error;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final auth = Provider.of<AuthProvider>(context, listen: false);

    return Scaffold(
      appBar: AppBar(title: const Text('Login')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const SizedBox(height: 24),
            Text(
              'Welcome back',
              style: Theme.of(context).textTheme.headlineSmall,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              'Sign in to manage your bookings',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            const SizedBox(height: 32),
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
              controller: _passwordController,
              decoration: const InputDecoration(
                labelText: 'Password',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.lock_outline),
              ),
              obscureText: true,
            ),
            Align(
              alignment: Alignment.centerRight,
              child: TextButton(
                onPressed: _loading
                    ? null
                    : () => Navigator.pushNamed(context, Routes.forgotPassword),
                child: const Text('Forgot password?'),
              ),
            ),
            const SizedBox(height: 8),
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
                      final emailError =
                          ValidationHelper.validateEmail(_emailController.text);
                      if (emailError != null) {
                        setState(() => _error = emailError);
                        return;
                      }
                      if (_passwordController.text.trim().isEmpty) {
                        setState(() => _error = 'Password is required');
                        return;
                      }

                      setState(() {
                        _loading = true;
                        _error = null;
                      });

                       final result = await auth.login(
                         _emailController.text.trim().toLowerCase(),
                         _passwordController.text.trim(),
                       );

                      if (!context.mounted) return;

                      if (result == LoginResult.success) {
                        setState(() => _loading = false);
                        Provider.of<AppointmentProvider>(context, listen: false)
                            .setCurrentUser(auth.currentUser!);

                        final route = auth.currentUser!.isProfessional
                            ? Routes.professionalHome
                            : Routes.customerHome;
                        Navigator.pushReplacementNamed(context, route);
                      } else if (result == LoginResult.needsProfile) {
                        setState(() => _loading = false);
                        _showProfileCompletionDialog(auth);
                      } else {
                        setState(() {
                          _loading = false;
                          _error = 'Invalid email or password';
                        });
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
                  : const Text('Login'),
            ),
            const SizedBox(height: 12),
            TextButton(
              onPressed: () => Navigator.pushNamed(context, Routes.register),
              child: const Text("Don't have an account? Register"),
            ),
          ],
        ),
      ),
    );
  }

  void _showProfileCompletionDialog(AuthProvider auth) {
    final nameController = TextEditingController(text: _emailController.text.split('@')[0]);
    final phoneController = TextEditingController();
    String role = 'customer';
    String? specialty = serviceNames.first;
    
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setStateDialog) {
            return AlertDialog(
              title: const Text('Complete your profile'),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const Text('It looks like this is your first login. Please provide details to complete registration.'),
                    const SizedBox(height: 16),
                    TextField(
                      controller: nameController,
                      decoration: const InputDecoration(
                        labelText: 'Full name',
                        border: OutlineInputBorder(),
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: phoneController,
                      keyboardType: TextInputType.phone,
                      decoration: const InputDecoration(
                        labelText: 'Phone number',
                        border: OutlineInputBorder(),
                      ),
                    ),
                    const SizedBox(height: 16),
                    const Text('Account type', style: TextStyle(fontWeight: FontWeight.bold)),
                    SegmentedButton<String>(
                      segments: const [
                        ButtonSegment(
                          value: 'customer',
                          label: Text('Customer'),
                        ),
                        ButtonSegment(
                          value: 'professional',
                          label: Text('Professional'),
                        ),
                      ],
                      selected: {role},
                      onSelectionChanged: (selection) {
                        setStateDialog(() {
                          role = selection.first;
                        });
                      },
                    ),
                    if (role == 'professional') ...[
                      const SizedBox(height: 8),
                      DropdownButtonFormField<String>(
                        initialValue: specialty,
                        decoration: const InputDecoration(
                          labelText: 'Specialty',
                          border: OutlineInputBorder(),
                        ),
                        items: serviceNames
                            .map((name) => DropdownMenuItem(
                                  value: name,
                                  child: Text(name),
                                ))
                            .toList(),
                        onChanged: (val) {
                          setStateDialog(() {
                            specialty = val;
                          });
                        },
                      ),
                    ],
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () {
                    Navigator.pop(context);
                  },
                  child: const Text('Cancel'),
                ),
                ElevatedButton(
                  onPressed: () async {
                    if (nameController.text.trim().isEmpty) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Name is required')),
                      );
                      return;
                    }
                    if (phoneController.text.trim().isEmpty) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Phone number is required')),
                      );
                      return;
                    }
                    
                    final success = await auth.createProfile(
                      name: nameController.text.trim(),
                      phone: phoneController.text.trim(),
                      role: role,
                      specialty: role == 'professional' ? specialty ?? '' : '',
                    );
                    
                    if (success && context.mounted) {
                      Provider.of<AppointmentProvider>(context, listen: false)
                          .setCurrentUser(auth.currentUser!);
                      Navigator.pop(context); // close dialog
                      
                       final route = auth.currentUser!.isProfessional
                           ? Routes.professionalHome
                           : Routes.customerHome;
                       Navigator.pushReplacementNamed(context, route);
                    } else if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Failed to save profile')),
                      );
                    }
                  },
                  child: const Text('Save & Continue'),
                ),
              ],
            );
          },
        );
      },
    );
  }
}
