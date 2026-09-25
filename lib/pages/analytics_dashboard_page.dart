import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../helpers/analytics_service.dart';
import '../helpers/feature_gate.dart';
import '../helpers/semantic_color_helper.dart';
import '../l10n/app_localizations.dart';
import '../models/user.dart';
import '../providers/appointment_provider.dart';
import '../providers/auth_provider.dart';
import '../providers/business_provider.dart';
import '../providers/payment_provider.dart';
import '../repositories/user_repository.dart';
import '../widgets/app_drawer.dart';

class AnalyticsDashboardPage extends StatefulWidget {
  const AnalyticsDashboardPage({super.key});

  @override
  State<AnalyticsDashboardPage> createState() => _AnalyticsDashboardPageState();
}

class _AnalyticsDashboardPageState extends State<AnalyticsDashboardPage> {
  List<User> _staff = [];

  @override
  void initState() {
    super.initState();
    _loadStaff();
  }

  Future<void> _loadStaff() async {
    final businessId = context.read<BusinessProvider>().currentBusiness?.id;
    if (businessId == null) {
      return;
    }
    try {
      final userRepo = context.read<UserRepository>();
      final professionals = await userRepo.getProfessionals(businessId: businessId);
      if (mounted) {
        setState(() {
          _staff = professionals;
        });
      }
    } catch (_) {
      // ignore
    }
  }

  @override
  Widget build(BuildContext context) {
    final auth = Provider.of<AuthProvider>(context);
    final businessProvider = Provider.of<BusinessProvider>(context);
    final business = businessProvider.currentBusiness;
    final user = auth.currentUser;

    if (user == null || business == null) {
      return Scaffold(
        appBar: AppBar(title: Text(AppLocalizations.of(context)?.analyticsDashboard ?? 'Analytics Dashboard')),
        body: const Center(child: Text('Unauthorized')),
      );
    }

    if (!FeatureGate.isAvailable(business, 'analytics')) {
      return Scaffold(
        appBar: AppBar(title: Text(AppLocalizations.of(context)?.analyticsDashboard ?? 'Analytics Dashboard')),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Text(
              AppLocalizations.of(context)?.featureNotAvailable ?? 'This feature is not available on your current plan.',
              textAlign: TextAlign.center,
            ),
          ),
        ),
      );
    }

    final apptProvider = Provider.of<AppointmentProvider>(context);
    final paymentProvider = Provider.of<PaymentProvider>(context);
    final appointments = apptProvider.appointments;
    final payments = paymentProvider.payments;

    final metrics = AnalyticsService.aggregate(
      appointments: appointments,
      payments: payments,
      staff: _staff,
    );

    return Scaffold(
      appBar: AppBar(
        title: Text(AppLocalizations.of(context)?.analyticsDashboard ?? 'Analytics Dashboard'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () {
              final businessId = business.id;
              final now = DateTime.now();
              final start = DateTime(now.year, now.month, 1);
              final end = DateTime(now.year, now.month + 1, 1);
              apptProvider.loadAppointmentsInRange(businessId, start, end);
              paymentProvider.loadPaymentsForProfessionalInRange(null, start, end, businessId: businessId);
              _loadStaff();
            },
          ),
        ],
      ),
      drawer: AppDrawer(user: user, auth: auth),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Row(
            children: [
              Expanded(child: _buildMetricCard(AppLocalizations.of(context)?.totalBookings ?? 'Total Bookings', metrics.totalBookings.toString(), Icons.event)),
              const SizedBox(width: 16),
              Expanded(child: _buildMetricCard(AppLocalizations.of(context)?.revenueLabel ?? 'Revenue', '\$${metrics.revenueEstimate.toStringAsFixed(2)}', Icons.attach_money)),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(child: _buildRateCard(AppLocalizations.of(context)?.completedLabel ?? 'Completion Rate', '${(metrics.completionRate * 100).toStringAsFixed(1)}%', SemanticColorHelper.successOf(Theme.of(context).colorScheme))),
              const SizedBox(width: 16),
              Expanded(child: _buildRateCard(AppLocalizations.of(context)?.statusCancelled ?? 'Cancellation Rate', '${(metrics.cancellationRate * 100).toStringAsFixed(1)}%', SemanticColorHelper.errorOf(Theme.of(context).colorScheme))),
            ],
          ),
          const SizedBox(height: 24),
          _buildSectionTitle(AppLocalizations.of(context)?.peakHours ?? 'Peak Hours'),
          const SizedBox(height: 8),
          _buildPeakHoursChart(metrics.peakHours),
          const SizedBox(height: 24),
          _buildSectionTitle(AppLocalizations.of(context)?.staffUtilization ?? 'Staff Utilization'),
          const SizedBox(height: 8),
          _buildStaffUtilizationList(metrics.staffUtilization, _staff),
        ],
      ),
    );
  }

  Widget _buildMetricCard(String title, String value, IconData icon) {
    final scheme = Theme.of(context).colorScheme;
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Icon(icon, size: 32, color: scheme.onSurfaceVariant),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: TextStyle(color: scheme.onSurfaceVariant, fontSize: 12)),
                  Text(value, style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRateCard(String title, String value, Color color) {
    final scheme = Theme.of(context).colorScheme;
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Icon(Icons.pie_chart_outline, size: 32, color: color),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: TextStyle(color: scheme.onSurfaceVariant, fontSize: 12)),
                  Text(value, style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: color)),
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
      child: Text(title, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
    );
  }

  Widget _buildPeakHoursChart(Map<int, int> peakHours) {
    final scheme = Theme.of(context).colorScheme;
    if (peakHours.isEmpty) {
      return const Card(
        child: Padding(
          padding: EdgeInsets.all(24),
          child: Text('No data available for peak hours.', textAlign: TextAlign.center),
        ),
      );
    }

    final sortedHours = peakHours.entries.toList()..sort((a, b) => a.key.compareTo(b.key));
    final maxCount = sortedHours.map((e) => e.value).reduce((a, b) => a > b ? a : b);

    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ...sortedHours.map((entry) {
              final hourLabel = '${entry.key.toString().padLeft(2, '0')}:00';
              final barWidth = maxCount > 0 ? (entry.value / maxCount) : 0.0;
              return Padding(
                padding: const EdgeInsets.symmetric(vertical: 4),
                child: Row(
                  children: [
                    SizedBox(width: 60, child: Text(hourLabel, style: const TextStyle(fontSize: 12))),
                    Expanded(
                      child: Stack(
                        children: [
                          Container(
                            height: 20,
                            decoration: BoxDecoration(
                              color: scheme.surfaceContainerHighest,
                              borderRadius: BorderRadius.circular(4),
                            ),
                          ),
                          FractionallySizedBox(
                            widthFactor: barWidth,
                            child: Container(
                              height: 20,
                              decoration: BoxDecoration(
                                color: scheme.primary,
                                borderRadius: BorderRadius.circular(4),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(entry.value.toString(), style: const TextStyle(fontSize: 12)),
                  ],
                ),
              );
            }).toList(),
          ],
        ),
      ),
    );
  }

  Widget _buildStaffUtilizationList(Map<String, double> utilization, List<User> staff) {
    if (utilization.isEmpty) {
      return const Card(
        child: Padding(
          padding: EdgeInsets.all(24),
          child: Text('No staff utilization data available.', textAlign: TextAlign.center),
        ),
      );
    }

    final staffMap = {for (final s in staff) s.id: s};

    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: utilization.entries.map((entry) {
            final member = entry.key == 'overall' ? null : staffMap[entry.key];
            final label = entry.key == 'overall' ? 'Overall' : (member?.name ?? 'Unknown');
            final percentage = (entry.value * 100).toStringAsFixed(1);
            return Padding(
              padding: const EdgeInsets.symmetric(vertical: 8),
              child: Row(
                children: [
                  Expanded(child: Text(label, style: const TextStyle(fontSize: 14))),
                  Text('$percentage%', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                ],
              ),
            );
          }).toList(),
        ),
      ),
    );
  }
}
