import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../l10n/app_localizations.dart';
import '../models/appointment.dart';
import '../models/payment.dart';
import '../providers/appointment_provider.dart';
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
  PaymentMethod _selectedMethod = PaymentMethod.cash;
  final _formKey = GlobalKey<FormState>();
  bool _isSubmitting = false;

  @override
  void dispose() {
    _amountController.dispose();
    super.dispose();
  }

  Future<void> _submitPayment() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSubmitting = true);

    try {
      final appointment = widget.appointment;
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
        specialty: ScheduleHelper.parseServiceCategory(appointment.service),
        appointmentDate: appointment.dateTime,
        appointmentTime:
            '${appointment.dateTime.hour.toString().padLeft(2, '0')}:${appointment.dateTime.minute.toString().padLeft(2, '0')}',
        appointmentDurationMinutes: appointment.durationMinutes,
        amount: double.parse(_amountController.text),
        method: _selectedMethod,
        status: PaymentStatus.completed,
        receiptGenerated: true,
      );

      final paymentProvider =
          Provider.of<PaymentProvider>(context, listen: false);
      await paymentProvider.recordPayment(payment);

      if (!mounted) return;

      final appointmentProvider = Provider.of<AppointmentProvider>(context, listen: false);
      await appointmentProvider.linkPaymentToAppointment(
        appointment.id!,
        payment.id ?? '',
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
      appBar: AppBar(title: Text(AppLocalizations.of(context)?.recordPayment ?? 'Record Payment')),
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