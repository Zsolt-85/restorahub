import 'package:flutter/material.dart';
import 'package:share_plus/share_plus.dart';

import '../models/payment.dart';

class ReceiptPage extends StatelessWidget {
  final Payment payment;

  const ReceiptPage({super.key, required this.payment});

  String get _receiptNumber => 'RCP-${payment.id?.substring(0, 8) ?? 'XXXX'}';

  String get _formattedAmount =>
      '${payment.currency} ${payment.amount.toStringAsFixed(2)}';

  Future<void> _shareReceipt(BuildContext context) async {
    final lines = [
      '===== RESTORAHUB RECEIPT =====',
      'Receipt: $_receiptNumber',
      '',
      'APPOINTMENT DETAILS',
      'Service: ${payment.service}',
      'Date: ${payment.appointmentDate.toLocal()}',
      'Time: ${payment.appointmentTime}',
      '',
      'CUSTOMER',
      'Name: ${payment.customerName}',
      'Phone: ${payment.customerPhone}',
      'Email: ${payment.customerEmail}',
      '',
      'PROFESSIONAL',
      'Name: ${payment.professionalName}',
      'Phone: ${payment.professionalPhone}',
      'Email: ${payment.professionalEmail}',
      '',
      'PAYMENT',
      'Amount: $_formattedAmount',
      'Method: ${payment.methodLabel}',
      'Status: ${payment.statusLabel}',
      '',
      'Thank you for choosing RestoraHub!',
    ].join('\n');

    await Share.share(lines, subject: 'Receipt $_receiptNumber');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Receipt'),
        actions: [
          IconButton(
            icon: const Icon(Icons.share),
            onPressed: () => _shareReceipt(context),
            tooltip: 'Share receipt',
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            const Text(
              'RESTORAHUB',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                letterSpacing: 3,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              _receiptNumber,
              style: Theme.of(context).textTheme.bodySmall,
            ),
            const SizedBox(height: 24),
            const Divider(thickness: 1),
            const SizedBox(height: 16),
            _sectionTitle('APPOINTMENT DETAILS'),
            const SizedBox(height: 8),
            _detailRow('Service', payment.service),
            _detailRow('Date', payment.appointmentDate.toLocal().toString().split(' ').first),
            _detailRow('Time', payment.appointmentTime),
            _detailRow('Duration', '${payment.appointmentDurationMinutes} min'),
            const SizedBox(height: 16),
            const Divider(thickness: 1),
            const SizedBox(height: 16),
            _sectionTitle('CUSTOMER'),
            const SizedBox(height: 8),
            _detailRow('Name', payment.customerName),
            _detailRow('Phone', payment.customerPhone),
            _detailRow('Email', payment.customerEmail),
            const SizedBox(height: 16),
            const Divider(thickness: 1),
            const SizedBox(height: 16),
            _sectionTitle('PROFESSIONAL'),
            const SizedBox(height: 8),
            _detailRow('Name', payment.professionalName),
            _detailRow('Phone', payment.professionalPhone),
            _detailRow('Email', payment.professionalEmail),
            const SizedBox(height: 16),
            const Divider(thickness: 1),
            const SizedBox(height: 16),
            _sectionTitle('PAYMENT'),
            const SizedBox(height: 8),
            _detailRow('Amount', _formattedAmount),
            _detailRow('Method', payment.methodLabel),
            _detailRow('Status', payment.statusLabel),
            _detailRow('Payment ID', payment.id ?? 'N/A'),
            const SizedBox(height: 24),
            const Divider(thickness: 1),
            const SizedBox(height: 16),
            Text(
              'Thank you for choosing RestoraHub!',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    fontStyle: FontStyle.italic,
                  ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              'Generated: ${DateTime.now().toLocal()}',
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ],
        ),
      ),
    );
  }

  Widget _sectionTitle(String title) {
    return Align(
      alignment: Alignment.centerLeft,
      child: Text(
        title,
        style: const TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  Widget _detailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(
              label,
              style: const TextStyle(fontWeight: FontWeight.w500),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(),
            ),
          ),
        ],
      ),
    );
  }
}