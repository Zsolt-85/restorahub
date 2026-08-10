import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/appointment.dart';
import '../providers/appointment_provider.dart';
import '../providers/auth_provider.dart';
import '../providers/payment_provider.dart';
import '../helpers/format_helper.dart';

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
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      final professionalId = authProvider.currentUser?.id ?? '';
      Provider.of<PaymentProvider>(context, listen: false)
          .loadPaymentsForProfessionalInRange(
        professionalId,
        _startOfRange(),
        _endOfRange(),
      );
    });
  }

  DateTime _startOfRange() {
    switch (_selectedRange) {
      case 'month':
        return DateTime(_selectedYear, _selectedMonth);
      case 'day':
        return DateTime(DateTime.now().year, DateTime.now().month, DateTime.now().day);
      case 'year':
        return DateTime(_selectedYear);
      default:
        return DateTime(_selectedYear, _selectedMonth);
    }
  }

  DateTime _endOfRange() {
    switch (_selectedRange) {
      case 'month':
        return DateTime(_selectedYear, _selectedMonth + 1);
      case 'day':
        return DateTime.now().add(const Duration(days: 1));
      case 'year':
        return DateTime(_selectedYear + 1);
      default:
        return DateTime(_selectedYear, _selectedMonth + 1);
    }
  }

  @override
  Widget build(BuildContext context) {
    final auth = Provider.of<AuthProvider>(context);
    final apptProvider = Provider.of<AppointmentProvider>(context);
    final paymentProvider = Provider.of<PaymentProvider>(context);
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
              'Revenue',
              _getRevenueLabel(paymentProvider),
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
        leading: const CircleAvatar(
          child: Icon(Icons.spa_outlined),
        ),
        title: Text(appt.service),
        subtitle: Text(
          '${appt.professionalName ?? "N/A"} \u2014 ${FormatHelper.formatDateTime(appt.dateTime)}',
        ),
        trailing: Text(
          appt.status.displayLabel,
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
    case AppointmentStatus.cancelledByCustomer:
    case AppointmentStatus.cancelledByProfessional:
      return Colors.red;
    case AppointmentStatus.noShow:
      return Colors.grey;
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

  String _getRevenueLabel(PaymentProvider provider) {
    final revenue = provider.totalRevenue;
    return '\$${revenue.toStringAsFixed(2)}';
  }
}