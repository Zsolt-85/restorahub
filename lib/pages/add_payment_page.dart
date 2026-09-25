import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../l10n/app_localizations.dart';
import '../models/appointment.dart';
import '../models/payment.dart';
import '../providers/appointment_provider.dart';
import '../providers/business_provider.dart';
import '../providers/payment_provider.dart';
import '../helpers/schedule_helper.dart';
import '../helpers/format_helper.dart';

class AddPaymentPage extends StatefulWidget {
  final Appointment appointment;

  const AddPaymentPage({super.key, required this.appointment});

  @override
  State<AddPaymentPage> createState() => _AddPaymentPageState();
}

class _AddPaymentPageState extends State<AddPaymentPage> {
  final _amountController = TextEditingController();
  final _depositController = TextEditingController();
  PaymentMethod _selectedMethod = PaymentMethod.cash;
  final _formKey = GlobalKey<FormState>();
  bool _isSubmitting = false;

  @override
  void dispose() {
    _amountController.dispose();
    _depositController.dispose();
    super.dispose();
  }

  /// Prefills the deposit from business policy while the field is untouched.
  /// Staff can still override or clear it before submitting.
  void _prefillDepositFromPolicy() {
    if (_depositController.text.trim().isNotEmpty) return;
    final amount = double.tryParse(_amountController.text.trim());
    if (amount == null || amount <= 0) return;
    final settings = Provider.of<BusinessProvider>(context, listen: false)
        .currentBusiness
        ?.settings;
    if (settings == null || !settings.isDepositRequired) return;
    final deposit = amount * settings.effectiveDepositPercent / 100;
    _depositController.text = deposit.toStringAsFixed(2);
  }

  Future<void> _submitPayment() async {
    if (!_formKey.currentState!.validate()) return;

    // Never record a payment that cannot be linked back afterwards.
    if (widget.appointment.id == null || widget.appointment.id!.isEmpty) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content:
                Text('Cannot record payment: missing appointment reference')),
      );
      return;
    }

    setState(() => _isSubmitting = true);

    try {
      final appointment = widget.appointment;
      final depositText = _depositController.text.trim();
      final payment = Payment(
        appointmentId: appointment.id ?? '',
        customerId: appointment.customerId ?? '',
        customerName: appointment.customerName ?? 'Unknown',
        customerPhone: appointment.customerPhone ?? '',
        customerEmail: appointment.customerEmail ?? '',
        professionalId: appointment.professionalId ?? '',
        professionalName: appointment.professionalName ?? 'Unknown',
        professionalPhone: appointment.professionalPhone ?? '',
        professionalEmail: appointment.professionalEmail ?? '',
        service: appointment.service,
        staffCategory: ScheduleHelper.parseServiceCategory(appointment.service),
        businessId: appointment.businessId,
        appointmentDate: appointment.dateTime,
        appointmentTime:
            '${appointment.dateTime.hour.toString().padLeft(2, '0')}:${appointment.dateTime.minute.toString().padLeft(2, '0')}',
        appointmentDurationMinutes: appointment.durationMinutes,
        amount: double.parse(_amountController.text),
        depositAmount: depositText.isEmpty ? 0.0 : double.parse(depositText),
        method: _selectedMethod,
        status: PaymentStatus.completed,
        receiptGenerated: true,
      );

      final paymentProvider =
          Provider.of<PaymentProvider>(context, listen: false);
      final paymentId = await paymentProvider.recordPayment(payment);

      if (!mounted) return;

      final appointmentProvider =
          Provider.of<AppointmentProvider>(context, listen: false);
      await appointmentProvider.linkPaymentToAppointment(
        appointment.id!,
        paymentId,
      );

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Payment recorded and receipt generated')),
      );

      Navigator.pop(context, true);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to record payment: $e')),
      );
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final appointment = widget.appointment;

    return Scaffold(
      appBar: AppBar(
          title: Text(
              AppLocalizations.of(context)?.recordPayment ?? 'Record Payment')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: ListView(
            children: [
              Card(
                margin: const EdgeInsets.only(bottom: 16),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        appointment.service,
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        '${FormatHelper.formatDateTime(appointment.dateTime)} · ${appointment.durationMinutes} min',
                        style: Theme.of(context).textTheme.bodyMedium,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Customer: ${appointment.customerName ?? 'N/A'}',
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                      Text(
                        'Professional: ${appointment.professionalName ?? 'N/A'}',
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                    ],
                  ),
                ),
              ),
              TextFormField(
                controller: _amountController,
                decoration: const InputDecoration(
                  labelText: 'Amount',
                  prefixText: '€ ',
                  border: OutlineInputBorder(),
                ),
                keyboardType: const TextInputType.numberWithOptions(
                  decimal: true,
                  signed: false,
                ),
                onChanged: (_) => _prefillDepositFromPolicy(),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Please enter an amount';
                  }
                  final amount = double.tryParse(value.trim());
                  if (amount == null || amount <= 0) {
                    return 'Please enter a valid amount';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _depositController,
                decoration: const InputDecoration(
                  labelText: 'Deposit (optional)',
                  prefixText: '€ ',
                  border: OutlineInputBorder(),
                ),
                keyboardType: const TextInputType.numberWithOptions(
                  decimal: true,
                  signed: false,
                ),
                validator: (value) {
                  final text = value?.trim() ?? '';
                  if (text.isEmpty) return null;
                  final deposit = double.tryParse(text);
                  if (deposit == null || deposit < 0) {
                    return 'Please enter a valid deposit';
                  }
                  final total = double.tryParse(_amountController.text.trim());
                  if (total != null && deposit > total) {
                    return 'Deposit cannot exceed the total amount';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<PaymentMethod>(
                initialValue: _selectedMethod,
                decoration: const InputDecoration(
                  labelText: 'Payment Method',
                  border: OutlineInputBorder(),
                ),
                items: PaymentMethod.values.map((method) {
                  return DropdownMenuItem(
                    value: method,
                    child: Text(method.name.toUpperCase()),
                  );
                }).toList(),
                onChanged: (value) {
                  if (value != null) {
                    setState(() => _selectedMethod = value);
                  }
                },
              ),
              const SizedBox(height: 24),
              FilledButton(
                onPressed: _isSubmitting ? null : _submitPayment,
                child: _isSubmitting
                    ? const SizedBox(
                        width: 24,
                        height: 24,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : const Text('Record Payment'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
