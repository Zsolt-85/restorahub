import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/appointment.dart';
import '../providers/appointment_provider.dart';
import '../providers/auth_provider.dart';

class AnalyticsPage extends StatefulWidget {
  const AnalyticsPage({super.key});

  @override
  State<AnalyticsPage> createState() => _AnalyticsPageState();
}

class _AnalyticsPageState extends State<AnalyticsPage> {
  final int _selectedYear = DateTime.now().year;
  final int _selectedMonth = DateTime.now().month;
  String _selectedRange = 'month';

  @override
  Widget build(BuildContext context) {
    final auth = Provider.of<AuthProvider>(context);
    final apptProvider = Provider.of<AppointmentProvider>(context);
    final user = auth.currentUser;

    if (user == null || !user.isProfessional) {
      return Scaffold(
        appBar: AppBar(title: const Text('Analytics')),
        body: const Center(
          child: Text('Analytics is available for professionals only'),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(title: const Text('Analytics')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildRangeSelector(),
            const SizedBox(height: 24),
            _buildStatCard(
              'Total Bookings',
              _getTotalBookings(apptProvider).toString(),
              Icons.event,
            ),
            const SizedBox(height: 16),
            _buildStatCard(
              'Completed',
              apptProvider.completedAppointments.length.toString(),
              Icons.check_circle,
            ),
            const SizedBox(height: 16),
            _buildStatCard(
              'Pending',
              apptProvider.pendingAppointments.length.toString(),
              Icons.schedule,
            ),
            const SizedBox(height: 16),
            _buildStatCard(
              'Cancelled',
              apptProvider.cancelledAppointments.length.toString(),
              Icons.cancel,
            ),
            const SizedBox(height: 24),
            _buildStatCard(
              'Monthly Revenue',
              _getRevenueLabel(apptProvider),
              Icons.attach_money,
            ),
            const SizedBox(height: 16),
            _buildSectionTitle('Appointments'),
            const SizedBox(height: 8),
            if (apptProvider.currentAppointments.isEmpty)
              const Center(
                child: Padding(
                  padding: EdgeInsets.all(32),
                  child: Text('No upcoming appointments'),
                ),
              )
            else
              ...apptProvider.currentAppointments.map((appt) {
                return _buildAppointmentTile(appt);
              }),
          ],
        ),
      ),
    );
  }

  Widget _buildRangeSelector() {
    return SegmentedButton<String>(
      segments: const [
        ButtonSegment(value: 'month', label: Text('Month')),
        ButtonSegment(value: 'day', label: Text('Day')),
        ButtonSegment(value: 'year', label: Text('Year')),
      ],
      selected: {_selectedRange},
      onSelectionChanged: (selection) {
        setState(() {
          _selectedRange = selection.first;
        });
      },
    );
  }

Widget _buildStatCard(String title, String value, IconData icon) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Icon(icon, size: 32, color: Colors.blueGrey),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      color: Colors.grey,
                      fontSize: 12,
                    ),
                  ),
                  Text(
                    value,
                    style: const TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: const TextStyle(
        fontSize: 18,
        fontWeight: FontWeight.bold,
      ),
    );
  }

  Widget _buildAppointmentTile(Appointment appt) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        leading: CircleAvatar(
          child: Icon(Icons.spa_outlined),
        ),
        title: Text(appt.service),
        subtitle: Text(
          '${appt.professionalName ?? "N/A"} \u2014 ${appt.dateTime.toLocal()}',
        ),
        trailing: Text(
          appt.status.name.toUpperCase(),
          style: TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w600,
            color: _statusColor(appt.status),
          ),
        ),
      ),
    );
  }

  Color _statusColor(AppointmentStatus status) {
    switch (status) {
      case AppointmentStatus.pending:
        return Colors.orange;
      case AppointmentStatus.confirmed:
        return Colors.green;
      case AppointmentStatus.completed:
        return Colors.blue;
      case AppointmentStatus.cancelled:
        return Colors.red;
    }
  }

  int _getTotalBookings(AppointmentProvider provider) {
    switch (_selectedRange) {
      case 'month':
        return provider.getAppointmentCountForMonth(_selectedYear, _selectedMonth);
      case 'day':
        return provider.appointments
            .where(
              (a) =>
                  a.dateTime.year == DateTime.now().year &&
                  a.dateTime.month == DateTime.now().month &&
                  a.dateTime.day == DateTime.now().day,
            )
            .length;
      case 'year':
        return provider.getYearToDateAppointmentCount(_selectedYear);
      default:
        return 0;
    }
  }

  String _getRevenueLabel(AppointmentProvider provider) {
    switch (_selectedRange) {
      case 'month':
        final revenue = provider.getMonthlyRevenue(_selectedYear, _selectedMonth);
        return '\$${revenue.toStringAsFixed(2)}';
      case 'day':
        return '\$0.00';
      case 'year':
        double total = 0;
        for (int m = 1; m <= 12; m++) {
          total += provider.getMonthlyRevenue(_selectedYear, m);
        }
        return '\$${total.toStringAsFixed(2)}';
      default:
        return '\$0.00';
    }
  }
}