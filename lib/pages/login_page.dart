import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

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
            const SizedBox(height: 20),
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

                      final success = await auth.login(
                        _emailController.text.trim(),
                        _passwordController.text.trim(),
                      );

                      if (!mounted) return;

                      setState(() => _loading = false);

                      if (success) {
                        Provider.of<AppointmentProvider>(context, listen: false)
                            .setCurrentUser(auth.currentUser!);

                        final route = auth.currentUser!.isProfessional
                            ? '/professional_home'
                            : '/user_home';
                        Navigator.pushReplacementNamed(context, route);
                      } else {
                        setState(() => _error = 'Invalid email or password');
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
              onPressed: () => Navigator.pushNamed(context, '/register'),
              child: const Text("Don't have an account? Register"),
            ),
          ],
        ),
      ),
    );
  }
}
