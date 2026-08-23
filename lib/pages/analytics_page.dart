import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../l10n/app_localizations.dart';
import '../models/appointment.dart';
import '../providers/appointment_provider.dart';
import '../providers/auth_provider.dart';
import '../providers/business_provider.dart';
import '../providers/payment_provider.dart';
import '../helpers/format_helper.dart';
import '../helpers/csv_export_helper.dart' show exportAppointmentsCsv;
import '../widgets/charts/revenue_trend_chart.dart';
import '../widgets/charts/service_category_pie_chart.dart';
import '../widgets/charts/peak_hours_bar_chart.dart';

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
      final businessId = Provider.of<BusinessProvider>(context, listen: false).currentBusiness?.id;
      final start = _startOfRange();
      final end = _endOfRange();
      if (businessId != null && businessId.isNotEmpty) {
        Provider.of<AppointmentProvider>(context, listen: false)
            .loadAppointmentsInRange(businessId, start, end, professionalId: professionalId);
      }
      Provider.of<PaymentProvider>(context, listen: false)
          .loadPaymentsForProfessionalInRange(
        professionalId,
        start,
        end,
        businessId: businessId,
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
        appBar: AppBar(title: Text(AppLocalizations.of(context)?.analytics ?? 'Analytics')),
        body: Center(
          child: Text(AppLocalizations.of(context)?.analyticsProfessionalOnly ?? 'Analytics is available for professionals only'),
        ),
      );
    }

    final isLoading = apptProvider.isLoading;
    final appointments = apptProvider.appointments;
    final total = appointments.length;
    final completed = apptProvider.completedAppointments.length;
    final cancelled = apptProvider.cancelledAppointments.length;
    final noShow = appointments.where((a) => a.status == AppointmentStatus.noShow).length;

    final completionRate = total > 0 ? '${(completed / total * 100).toStringAsFixed(1)}%' : '0%';
    final cancellationRate = total > 0 ? '${(cancelled / total * 100).toStringAsFixed(1)}%' : '0%';
    final noShowRate = total > 0 ? '${(noShow / total * 100).toStringAsFixed(1)}%' : '0%';

    return Scaffold(
      appBar: AppBar(
        title: Text(AppLocalizations.of(context)?.analytics ?? 'Analytics'),
        actions: [
          IconButton(
            icon: const Icon(Icons.download),
            tooltip: 'Export CSV',
            onPressed: () async {
              await exportAppointmentsCsv(
                appointments,
                paymentProvider.payments,
              );
            },
          ),
        ],
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildRangeSelector(),
                  const SizedBox(height: 24),
                  Row(
                    children: [
                      Expanded(child: _buildStatCard(AppLocalizations.of(context)?.totalBookings ?? 'Total Bookings', total.toString(), Icons.event)),
                      const SizedBox(width: 16),
                      Expanded(child: _buildRateCard(AppLocalizations.of(context)?.completedLabel ?? 'Completion Rate', completionRate, Colors.green, Icons.check_circle)),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(child: _buildRateCard(AppLocalizations.of(context)?.statusCancelled ?? 'Cancellation Rate', cancellationRate, Colors.red, Icons.cancel)),
                      const SizedBox(width: 16),
                      Expanded(child: _buildRateCard('No-Show Rate', noShowRate, Colors.grey, Icons.person_off)),
                    ],
                  ),
                  const SizedBox(height: 16),
                  _buildStatCard(
                    AppLocalizations.of(context)?.revenueLabel ?? 'Revenue',
                    FormatHelper.formatCurrency(paymentProvider.totalRevenue, currency: paymentProvider.revenueCurrency),
                    Icons.attach_money,
                  ),
                   const SizedBox(height: 24),
                   _buildSectionTitle('Revenue Trend'),
                   const SizedBox(height: 8),
                   Card(
                     elevation: 2,
                     shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                     child: Padding(
                       padding: const EdgeInsets.all(12),
                       child: SizedBox(
                         height: 250,
                         child: RevenueTrendChart(
                           payments: paymentProvider.payments,
                           start: _startOfRange(),
                           end: _endOfRange(),
                           currency: paymentProvider.revenueCurrency,
                         ),
                       ),
                     ),
                   ),
                   const SizedBox(height: 24),
                   _buildSectionTitle(AppLocalizations.of(context)?.appointmentsSection ?? 'Appointments'),
                   const SizedBox(height: 8),
                   if (apptProvider.currentAppointments.isEmpty)
                     Center(
                       child: Padding(
                         padding: const EdgeInsets.all(32),
                         child: Text(AppLocalizations.of(context)?.noUpcomingAppointments ?? 'No upcoming appointments'),
                       ),
                     )
                   else
                     ...apptProvider.currentAppointments.map((appt) {
                       return _buildAppointmentTile(appt);
                     }),
                   const SizedBox(height: 24),
                    LayoutBuilder(
                      builder: (context, constraints) {
                        if (constraints.maxWidth < 600) {
                          return Column(
                            children: [
                               _buildChartCard('Service Categories', SizedBox(height: 320, child: ServiceCategoryPieChart(appointments: appointments))),
                               const SizedBox(height: 16),
                               _buildChartCard('Peak Hours', SizedBox(height: 320, child: PeakHoursBarChart(appointments: appointments))),
                            ],
                          );
                        }
                        return Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Expanded(child: _buildChartCard('Service Categories', SizedBox(height: 320, child: ServiceCategoryPieChart(appointments: appointments)))),
                            const SizedBox(width: 16),
                            Expanded(child: _buildChartCard('Peak Hours', SizedBox(height: 320, child: PeakHoursBarChart(appointments: appointments)))),
                          ],
                        );
                      },
                    ),
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
        final authProvider = Provider.of<AuthProvider>(context, listen: false);
        final professionalId = authProvider.currentUser?.id ?? '';
        final businessId = Provider.of<BusinessProvider>(context, listen: false).currentBusiness?.id;
        final start = _startOfRange();
        final end = _endOfRange();
        if (businessId != null && businessId.isNotEmpty) {
          Provider.of<AppointmentProvider>(context, listen: false)
              .loadAppointmentsInRange(businessId, start, end, professionalId: professionalId);
        }
        Provider.of<PaymentProvider>(context, listen: false)
            .loadPaymentsForProfessionalInRange(professionalId, start, end, businessId: businessId);
      },
    );
  }

  Widget _buildStatCard(String title, String value, IconData icon) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
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

  Widget _buildRateCard(String title, String value, Color color, IconData icon) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Icon(icon, size: 32, color: color),
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
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: color,
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
    return Padding(
      padding: const EdgeInsets.only(left: 4, bottom: 8),
      child: Text(
        title,
        style: const TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  Widget _buildChartCard(String title, Widget child) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      margin: const EdgeInsets.symmetric(horizontal: 4),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),
            child,
          ],
        ),
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
          _localizedStatus(context, appt.status),
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

  String _localizedStatus(BuildContext context, AppointmentStatus status) {
    final l10n = AppLocalizations.of(context);
    switch (status) {
      case AppointmentStatus.pending:
        return l10n?.statusPending ?? 'Pending';
      case AppointmentStatus.confirmed:
        return l10n?.statusConfirmed ?? 'Confirmed';
      case AppointmentStatus.completed:
        return l10n?.statusCompleted ?? 'Completed';
      case AppointmentStatus.cancelledByCustomer:
      case AppointmentStatus.cancelledByProfessional:
        return l10n?.statusCancelled ?? 'Cancelled';
      case AppointmentStatus.noShow:
        return 'No Show';
    }
  }
}
