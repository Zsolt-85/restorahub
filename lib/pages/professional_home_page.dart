import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../providers/appointment_provider.dart';
import 'settings_page.dart';

class ProfessionalHomePage extends StatefulWidget {
  const ProfessionalHomePage({Key? key}) : super(key: key);

  @override
  State<ProfessionalHomePage> createState() => _ProfessionalHomePageState();
}

class _ProfessionalHomePageState extends State<ProfessionalHomePage> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final auth = Provider.of<AuthProvider>(context, listen: false);
      final apptProvider =
          Provider.of<AppointmentProvider>(context, listen: false);
      if (auth.currentUser != null) {
        apptProvider.setCurrentUser(auth.currentUser!);
        apptProvider.loadAppointments();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final auth = Provider.of<AuthProvider>(context);
    final apptProvider = Provider.of<AppointmentProvider>(context);
    final appointments = apptProvider.filteredAppointments;

    // Auth guard
    if (auth.currentUser == null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        Navigator.pushNamedAndRemoveUntil(context, '/login', (_) => false);
      });
      return const SizedBox.shrink();
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text("Professional Dashboard"),
        actions: [
          IconButton(
            icon: const Icon(Icons.settings),
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const SettingsPage()),
            ),
          ),
        ],
      ),
      drawer: Drawer(
        child: ListView(
          padding: EdgeInsets.zero,
          children: [
            UserAccountsDrawerHeader(
              accountName: Text(auth.currentUser?.name ?? 'Unknown'),
              accountEmail: Text(auth.currentUser?.email ?? 'No Email'),
              currentAccountPicture: CircleAvatar(
                child: Text(
                  auth.currentUser?.name.substring(0, 1).toUpperCase() ?? 'P',
                  style: const TextStyle(fontSize: 24),
                ),
              ),
            ),
            ListTile(
              leading: const Icon(Icons.settings),
              title: const Text('Settings'),
              onTap: () {
                Navigator.pop(context);
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const SettingsPage()),
                );
              },
            ),
            ListTile(
              leading: const Icon(Icons.logout),
              title: const Text('Logout'),
              onTap: () {
                auth.logout();
                Navigator.pushNamedAndRemoveUntil(
                    context, '/login', (_) => false);
              },
            ),
          ],
        ),
      ),
      body: appointments.isEmpty
          ? const Center(child: Text("No bookings yet."))
          : ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: appointments.length,
              itemBuilder: (context, index) {
                final appt = appointments[index];
                return Card(
                  margin: const EdgeInsets.symmetric(vertical: 8),
                  child: ListTile(
                    title: Text(appt.service),
                    subtitle: Text(
                      "Customer: ${appt.customerName ?? 'N/A'}\nDate: ${appt.dateTime}\nPhone: ${appt.customerPhone ?? 'N/A'}",
                    ),
                  ),
                );
              },
            ),
    );
  }
}
