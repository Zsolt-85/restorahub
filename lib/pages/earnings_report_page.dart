import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:share_plus/share_plus.dart';

import '../l10n/app_localizations.dart';
import '../constants/routes.dart';
import '../models/payment.dart';
import '../providers/auth_provider.dart';
import '../providers/payment_provider.dart';

class EarningsReportPage extends StatefulWidget {
  const EarningsReportPage({super.key});

  @override
  State<EarningsReportPage> createState() => _EarningsReportPageState();
}

class _EarningsReportPageState extends State<EarningsReportPage> {
  DateTime _startDate = DateTime.now().subtract(const Duration(days: 30));
  DateTime _endDate = DateTime.now();
  String _rangeLabel = 'Last 30 days';

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      final professionalId = authProvider.currentUser?.id ?? '';
      Provider.of<PaymentProvider>(context, listen: false)
          .loadPaymentsForProfessionalInRange(
        professionalId,
        _startDate,
        _endDate,
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    final paymentProvider = context.watch<PaymentProvider>();
    final payments = paymentProvider.payments;
    final totalRevenue = paymentProvider.totalRevenue;
    final completedCount = paymentProvider.completedCount;
    final avgPerAppointment = completedCount > 0
        ? totalRevenue / completedCount
        : 0.0;

    return Scaffold(
      appBar: AppBar(title: Text(AppLocalizations.of(context)?.earningsReport ?? 'Earnings Report')),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: _pickDateRange,
                    child: Text(_rangeLabel),
                  ),
                ),
                const SizedBox(width: 8),
                FilledButton.icon(
                  icon: const Icon(Icons.share),
                  label: Text(AppLocalizations.of(context)?.share ?? 'Share'),
                  onPressed: payments.isEmpty
                      ? null
                      : () => _shareReport(payments, totalRevenue),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      children: [
                        _statColumn(
                          AppLocalizations.of(context)?.revenueLabel ?? 'Revenue',
                          '${payments.isEmpty ? "0.00" : payments.first.currency} ${totalRevenue.toStringAsFixed(2)}',
                        ),
                        _statColumn(
                          AppLocalizations.of(context)?.completedLabel ?? 'Completed',
                          '$completedCount',
                        ),
                        _statColumn(
                          AppLocalizations.of(context)?.avgLabel ?? 'Avg',
                          '${payments.isEmpty ? "0.00" : payments.first.currency} ${avgPerAppointment.toStringAsFixed(2)}',
                        ),
                      ],
                    ),
                  ),
            ),
          ),
          const SizedBox(height: 8),
          Expanded(
            child: payments.isEmpty
                ? Center(child: Text(AppLocalizations.of(context)?.noPaymentsRecorded ?? 'No payments recorded'))
                : ListView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    itemCount: payments.length,
                    itemBuilder: (context, index) {
                      final payment = payments[index];
                      return Card(
                        margin: const EdgeInsets.only(bottom: 8),
                        child: ListTile(
                          leading: const CircleAvatar(
                            child: Icon(Icons.payment),
                          ),
                          title: Text(payment.service),
                          subtitle: Text(
                            '${payment.customerName} · ${payment.methodLabel} · ${payment.appointmentDate.toLocal()}',
                          ),
                          trailing: Text(
                            '${payment.currency} ${payment.amount.toStringAsFixed(2)}',
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          onTap: () {
                            Navigator.pushNamed(
                              context,
                              Routes.receipt,
                              arguments: payment,
                            );
                          },
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }

  Widget _statColumn(String label, String value) {
    return Column(
      children: [
        Text(
          label,
          style: Theme.of(context).textTheme.bodySmall,
        ),
        Text(
          value,
          style: const TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 18,
          ),
        ),
      ],
    );
  }

  Future<void> _pickDateRange() async {
    final updated = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2020),
      lastDate: DateTime.now().add(const Duration(days: 365)),
      initialDateRange: DateTimeRange(start: _startDate, end: _endDate),
    );

    if (updated != null) {
      setState(() {
        _startDate = updated.start;
        _endDate = updated.end;
        _rangeLabel =
            '${_startDate.toLocal()} to ${_endDate.toLocal()}';
      });
      if (!mounted) return;
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      final professionalId = authProvider.currentUser?.id ?? '';
      Provider.of<PaymentProvider>(context, listen: false)
          .loadPaymentsForProfessionalInRange(
        professionalId,
        _startDate,
        _endDate,
      );
    }
  }

  void _shareReport(
    List<Payment> payments,
    double totalRevenue,
  ) async {
    final lines = [
      '===== RESTORAHUB EARNINGS REPORT =====',
      'Period: $_rangeLabel',
      '',
      'Total Revenue: ${payments.first.currency} ${totalRevenue.toStringAsFixed(2)}',
      'Completed Appointments: ${payments.length}',
      '',
      'INDIVIDUAL PAYMENTS',
      for (final p in payments) ...[
        '${p.appointmentDate.toLocal()} · ${p.service} · ${p.customerName} · ${p.currency} ${p.amount.toStringAsFixed(2)} · ${p.methodLabel}',
      ],
      '',
      'Generated by RestoraHub',
    ].join('\n');

    await Share.share(lines, subject: 'Earnings Report');
  }
}