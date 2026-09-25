import 'package:flutter/material.dart';

import '../exceptions/app_exception.dart';
import '../helpers/analytics_service.dart';
import '../models/payment.dart';
import '../repositories/payment_repository.dart';
import '../utils/app_logger.dart';

class PaymentProvider extends ChangeNotifier {
  final PaymentRepository _repository;

  PaymentProvider({required PaymentRepository repository})
      : _repository = repository;

  List<Payment> _payments = [];
  Payment? _selectedPayment;
  bool _isLoading = false;
  String? _error;

  List<Payment> get payments => _payments;
  Payment? get selectedPayment => _selectedPayment;
  bool get isLoading => _isLoading;
  String? get error => _error;

  void _beginLoading() {
    _isLoading = true;
    _error = null;
    notifyListeners();
  }

  void _endLoading([String? error]) {
    _isLoading = false;
    _error = error;
    notifyListeners();
  }

  double get totalRevenue {
    double sum = 0;
    for (final p in _payments) {
      if (p.status == PaymentStatus.completed) {
        sum += AnalyticsService.collectedFor(p);
      }
    }
    return sum;
  }

  String get revenueCurrency {
    final completed =
        _payments.where((p) => p.status == PaymentStatus.completed).toList();
    if (completed.isEmpty) return 'EUR';
    // Deterministic: most frequent currency wins, first-seen breaks ties.
    final counts = <String, int>{};
    for (final p in completed) {
      counts[p.currency] = (counts[p.currency] ?? 0) + 1;
    }
    var best = completed.first.currency;
    var bestCount = 0;
    for (final entry in counts.entries) {
      if (entry.value > bestCount) {
        best = entry.key;
        bestCount = entry.value;
      }
    }
    return best;
  }

  int get completedCount {
    int count = 0;
    for (final p in _payments) {
      if (p.status == PaymentStatus.completed) count++;
    }
    return count;
  }

  Future<void> loadPaymentsForProfessional(String professionalId,
      {String? businessId}) async {
    _beginLoading();
    try {
      _payments = await _repository.getPaymentsByProfessional(professionalId,
          businessId: businessId);
      _endLoading();
    } on AppException catch (e) {
      AppLogger.error('PaymentProvider.loadPaymentsForProfessional error: $e');
      _endLoading(e.message);
    } catch (e) {
      AppLogger.error('PaymentProvider.loadPaymentsForProfessional error: $e');
      _endLoading('Unexpected error loading payments');
    }
  }

  Future<void> loadPaymentsForProfessionalInRange(
      String? professionalId, DateTime start, DateTime end,
      {String? businessId}) async {
    _beginLoading();
    try {
      _payments = await _repository.getPaymentsByProfessionalInRange(
        professionalId,
        start,
        end,
        businessId: businessId,
      );
      _endLoading();
    } on AppException catch (e) {
      AppLogger.error(
          'PaymentProvider.loadPaymentsForProfessionalInRange error: $e');
      _endLoading(e.message);
    } catch (e) {
      AppLogger.error(
          'PaymentProvider.loadPaymentsForProfessionalInRange error: $e');
      _endLoading('Unexpected error loading payments');
    }
  }

  /// Records the payment and returns its document id.
  /// The passed [payment] is never mutated; the stored entry carries the id.
  Future<String> recordPayment(Payment payment) async {
    _beginLoading();
    try {
      final id = await _repository.recordPayment(payment);
      _payments.add(payment.copyWith(id: id));
      _endLoading();
      return id;
    } on AppException catch (e) {
      AppLogger.error('PaymentProvider.recordPayment error: $e');
      _endLoading(e.message);
      rethrow;
    } catch (e) {
      AppLogger.error('PaymentProvider.recordPayment error: $e');
      _endLoading('Unexpected error recording payment');
      rethrow;
    }
  }

  Future<void> updatePayment(Payment payment) async {
    _beginLoading();
    try {
      await _repository.updatePayment(payment);
      final index = _payments.indexWhere((p) => p.id == payment.id);
      if (index != -1) {
        _payments[index] = payment;
      }
      _endLoading();
    } on AppException catch (e) {
      AppLogger.error('PaymentProvider.updatePayment error: $e');
      _endLoading(e.message);
      rethrow;
    } catch (e) {
      AppLogger.error('PaymentProvider.updatePayment error: $e');
      _endLoading('Unexpected error updating payment');
      rethrow;
    }
  }

  Future<void> updatePaymentStatus(
      String paymentId, PaymentStatus status) async {
    _beginLoading();
    try {
      await _repository.updatePaymentStatus(paymentId, status);
      final index = _payments.indexWhere((p) => p.id == paymentId);
      if (index != -1) {
        _payments[index] = _payments[index].copyWith(status: status);
      }
      _endLoading();
    } on AppException catch (e) {
      AppLogger.error('PaymentProvider.updatePaymentStatus error: $e');
      _endLoading(e.message);
      rethrow;
    } catch (e) {
      AppLogger.error('PaymentProvider.updatePaymentStatus error: $e');
      _endLoading('Unexpected error updating payment');
      rethrow;
    }
  }

  void selectPayment(Payment? payment) {
    _selectedPayment = payment;
    notifyListeners();
  }
}
