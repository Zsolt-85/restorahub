import 'package:flutter/material.dart';

import '../models/payment.dart';
import '../repositories/payment_repository.dart';
import '../utils/app_logger.dart';

class PaymentProvider extends ChangeNotifier {
  final PaymentRepository _repository;

  PaymentProvider({required PaymentRepository repository})
      : _repository = repository;

  List<Payment> _payments = [];
  Payment? _selectedPayment;

  List<Payment> get payments => _payments;
  Payment? get selectedPayment => _selectedPayment;

  double get totalRevenue {
    double sum = 0;
    for (final p in _payments) {
      if (p.status == PaymentStatus.completed) {
        sum += p.amount;
      }
    }
    return sum;
  }

  int get completedCount {
    int count = 0;
    for (final p in _payments) {
      if (p.status == PaymentStatus.completed) count++;
    }
    return count;
  }

  Future<void> loadPaymentsForProfessional(String professionalId, {String? businessId}) async {
    try {
      _payments = await _repository.getPaymentsByProfessional(professionalId, businessId: businessId);
      notifyListeners();
    } catch (e) {
      AppLogger.error('PaymentProvider.loadPaymentsForProfessional error: $e');
    }
  }

  Future<void> loadPaymentsForProfessionalInRange(
    String professionalId,
    DateTime start,
    DateTime end,
    {String? businessId}
  ) async {
    try {
      _payments = await _repository.getPaymentsByProfessionalInRange(
        professionalId,
        start,
        end,
        businessId: businessId,
      );
      notifyListeners();
    } catch (e) {
      AppLogger.error('PaymentProvider.loadPaymentsForProfessionalInRange error: $e');
    }
  }

  Future<void> recordPayment(Payment payment) async {
    try {
      await _repository.recordPayment(payment);
      _payments.add(payment);
      notifyListeners();
    } catch (e) {
      AppLogger.error('PaymentProvider.recordPayment error: $e');
      rethrow;
    }
  }

  Future<void> updatePayment(Payment payment) async {
    try {
      await _repository.updatePayment(payment);
      final index = _payments.indexWhere((p) => p.id == payment.id);
      if (index != -1) {
        _payments[index] = payment;
      }
      notifyListeners();
    } catch (e) {
      AppLogger.error('PaymentProvider.updatePayment error: $e');
      rethrow;
    }
  }

  Future<void> updatePaymentStatus(
      String paymentId, PaymentStatus status) async {
    try {
      await _repository.updatePaymentStatus(paymentId, status);
      final index = _payments.indexWhere((p) => p.id == paymentId);
      if (index != -1) {
        _payments[index].status = status;
      }
      notifyListeners();
    } catch (e) {
      AppLogger.error('PaymentProvider.updatePaymentStatus error: $e');
      rethrow;
    }
  }

  void selectPayment(Payment? payment) {
    _selectedPayment = payment;
    notifyListeners();
  }
}