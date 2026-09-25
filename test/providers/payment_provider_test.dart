import 'package:flutter_test/flutter_test.dart';
import 'package:restorahub/exceptions/app_exception.dart';
import 'package:restorahub/models/payment.dart';
import 'package:restorahub/providers/payment_provider.dart';
import 'package:restorahub/repositories/payment_repository.dart';

class FailingPaymentRepository implements PaymentRepository {
  @override
  Future<Payment?> getPaymentByAppointment(String appointmentId,
          {String? businessId}) async =>
      throw const AppException('load failed');

  @override
  Future<List<Payment>> getPaymentsByProfessional(String professionalId,
          {String? businessId}) async =>
      throw const AppException('load failed');

  @override
  Future<List<Payment>> getPaymentsByProfessionalInRange(
    String? professionalId,
    DateTime start,
    DateTime end, {
    String? businessId,
  }) async =>
      throw const AppException('load failed');

  @override
  Future<String> recordPayment(Payment payment) async =>
      throw const AppException('record failed');

  @override
  Future<int> updatePayment(Payment payment) async =>
      throw const AppException('update failed');

  @override
  Future<int> updatePaymentStatus(
          String paymentId, PaymentStatus status) async =>
      throw const AppException('update failed');
}

class FakePaymentRepository implements PaymentRepository {
  final List<Payment> payments = [];

  @override
  Future<Payment?> getPaymentByAppointment(String appointmentId,
      {String? businessId}) async {
    final list = payments.where((p) => p.appointmentId == appointmentId).where(
        (p) =>
            businessId == null ||
            businessId.isEmpty ||
            p.businessId == null ||
            p.businessId == businessId);
    return list.isNotEmpty ? list.first : null;
  }

  @override
  Future<List<Payment>> getPaymentsByProfessional(String professionalId,
      {String? businessId}) async {
    return payments.where((p) => p.professionalId == professionalId).toList();
  }

  @override
  Future<List<Payment>> getPaymentsByProfessionalInRange(
      String? professionalId, DateTime start, DateTime end,
      {String? businessId}) async {
    return payments.where((p) {
      if (professionalId != null &&
          professionalId.isNotEmpty &&
          p.professionalId != professionalId) {
        return false;
      }
      return p.appointmentDate
              .isAfter(start.subtract(const Duration(seconds: 1))) &&
          p.appointmentDate.isBefore(end.add(const Duration(seconds: 1)));
    }).toList();
  }

  @override
  Future<String> recordPayment(Payment payment) async {
    final stored = payment.id == null
        ? payment.copyWith(id: 'PAY-${payments.length + 1}')
        : payment;
    payments.add(stored);
    return stored.id!;
  }

  @override
  Future<int> updatePayment(Payment payment) async {
    final idx = payments.indexWhere((p) => p.id == payment.id);
    if (idx != -1) {
      payments[idx] = payment;
      return 1;
    }
    return 0;
  }

  @override
  Future<int> updatePaymentStatus(
      String paymentId, PaymentStatus status) async {
    final idx = payments.indexWhere((p) => p.id == paymentId);
    if (idx != -1) {
      payments[idx] = payments[idx].copyWith(status: status);
      return 1;
    }
    return 0;
  }
}

void main() {
  group('PaymentProvider Tests', () {
    late FakePaymentRepository repository;
    late PaymentProvider provider;

    setUp(() {
      repository = FakePaymentRepository();
      provider = PaymentProvider(repository: repository);
    });

    test('Initial state is empty', () {
      expect(provider.payments, isEmpty);
      expect(provider.selectedPayment, isNull);
      expect(provider.totalRevenue, 0.0);
      expect(provider.completedCount, 0);
    });

    test('recordPayment adds a payment to the list and updates revenue',
        () async {
      final payment = Payment(
        id: 'PAY-1',
        appointmentId: 'appt-1',
        customerId: 'cust-1',
        customerName: 'Alice',
        customerPhone: '',
        customerEmail: '',
        professionalId: 'prof-1',
        professionalName: 'Bob',
        professionalPhone: '',
        professionalEmail: '',
        service: 'Massage',
        staffCategory: '',
        appointmentDate: DateTime(2026, 8, 1, 10, 0),
        appointmentTime: '10:00',
        appointmentDurationMinutes: 60,
        amount: 80.0,
        method: PaymentMethod.card,
        status: PaymentStatus.completed,
        receiptGenerated: true,
      );

      await provider.recordPayment(payment);

      expect(provider.payments.length, 1);
      expect(provider.totalRevenue, 80.0);
      expect(provider.completedCount, 1);
    });

    test('totalRevenue and completedCount only count completed payments',
        () async {
      final p1 = Payment(
        id: '1',
        appointmentId: 'a-1',
        customerId: 'c-1',
        customerName: 'A',
        customerPhone: '',
        customerEmail: '',
        professionalId: 'p-1',
        professionalName: 'B',
        professionalPhone: '',
        professionalEmail: '',
        service: 'S',
        staffCategory: '',
        appointmentDate: DateTime.now(),
        appointmentTime: '',
        appointmentDurationMinutes: 60,
        amount: 50.0,
        status: PaymentStatus.completed,
      );
      final p2 = Payment(
        id: '2',
        appointmentId: 'a-2',
        customerId: 'c-2',
        customerName: 'A',
        customerPhone: '',
        customerEmail: '',
        professionalId: 'p-1',
        professionalName: 'B',
        professionalPhone: '',
        professionalEmail: '',
        service: 'S',
        staffCategory: '',
        appointmentDate: DateTime.now(),
        appointmentTime: '',
        appointmentDurationMinutes: 60,
        amount: 70.0,
        status: PaymentStatus.pending,
      );

      await provider.recordPayment(p1);
      await provider.recordPayment(p2);

      expect(provider.payments.length, 2);
      expect(provider.totalRevenue, 50.0);
      expect(provider.completedCount, 1);
    });

    test('updatePayment updates existing payment in the list', () async {
      final p1 = Payment(
        id: '1',
        appointmentId: 'a-1',
        customerId: 'c-1',
        customerName: 'A',
        customerPhone: '',
        customerEmail: '',
        professionalId: 'p-1',
        professionalName: 'B',
        professionalPhone: '',
        professionalEmail: '',
        service: 'S',
        staffCategory: '',
        appointmentDate: DateTime.now(),
        appointmentTime: '',
        appointmentDurationMinutes: 60,
        amount: 50.0,
        status: PaymentStatus.pending,
      );
      await provider.recordPayment(p1);

      final updated =
          p1.copyWith(status: PaymentStatus.completed, amount: 60.0);
      await provider.updatePayment(updated);

      expect(provider.payments.first.status, PaymentStatus.completed);
      expect(provider.payments.first.amount, 60.0);
      expect(provider.totalRevenue, 60.0);
    });

    test('loadPaymentsForProfessionalInRange filters list', () async {
      final start = DateTime(2026, 8, 1);
      final end = DateTime(2026, 8, 30);

      final p1 = Payment(
        id: '1',
        appointmentId: 'a-1',
        customerId: 'c-1',
        customerName: 'A',
        customerPhone: '',
        customerEmail: '',
        professionalId: 'prof-1',
        professionalName: 'B',
        professionalPhone: '',
        professionalEmail: '',
        service: 'S',
        staffCategory: '',
        appointmentDate: DateTime(2026, 8, 15),
        appointmentTime: '',
        appointmentDurationMinutes: 60,
        amount: 50.0,
        status: PaymentStatus.completed,
      );
      final p2 = Payment(
        id: '2',
        appointmentId: 'a-2',
        customerId: 'c-2',
        customerName: 'A',
        customerPhone: '',
        customerEmail: '',
        professionalId: 'prof-1',
        professionalName: 'B',
        professionalPhone: '',
        professionalEmail: '',
        service: 'S',
        staffCategory: '',
        appointmentDate: DateTime(2026, 9, 5), // out of range
        appointmentTime: '',
        appointmentDurationMinutes: 60,
        amount: 70.0,
        status: PaymentStatus.completed,
      );

      await repository.recordPayment(p1);
      await repository.recordPayment(p2);

      await provider.loadPaymentsForProfessionalInRange('prof-1', start, end);

      expect(provider.payments.length, 1);
      expect(provider.payments.first.id, '1');
    });

    test('initial loading contract is idle with no error', () {
      expect(provider.isLoading, isFalse);
      expect(provider.error, isNull);
    });

    test('successful load clears loading and error', () async {
      await provider.loadPaymentsForProfessional('prof-1');

      expect(provider.isLoading, isFalse);
      expect(provider.error, isNull);
    });

    test('failed load surfaces error instead of staying silent', () async {
      final failing = PaymentProvider(repository: FailingPaymentRepository());

      await failing.loadPaymentsForProfessional('prof-1');

      expect(failing.isLoading, isFalse);
      expect(failing.error, 'load failed');
      expect(failing.payments, isEmpty);
    });

    test('failed record sets error and still rethrows', () async {
      final failing = PaymentProvider(repository: FailingPaymentRepository());
      final payment = Payment(
        appointmentId: 'a-1',
        customerId: 'c-1',
        customerName: 'A',
        customerPhone: '',
        customerEmail: '',
        professionalId: 'p-1',
        professionalName: 'B',
        professionalPhone: '',
        professionalEmail: '',
        service: 'S',
        staffCategory: '',
        appointmentDate: DateTime.now(),
        appointmentTime: '',
        appointmentDurationMinutes: 60,
        amount: 50.0,
      );

      await expectLater(
          () => failing.recordPayment(payment), throwsA(isA<AppException>()));
      expect(failing.error, 'record failed');
    });

    test('updatePaymentStatus replaces entry via copyWith', () async {
      final payment = Payment(
        id: '1',
        appointmentId: 'a-1',
        customerId: 'c-1',
        customerName: 'A',
        customerPhone: '',
        customerEmail: '',
        professionalId: 'p-1',
        professionalName: 'B',
        professionalPhone: '',
        professionalEmail: '',
        service: 'S',
        staffCategory: '',
        appointmentDate: DateTime.now(),
        appointmentTime: '',
        appointmentDurationMinutes: 60,
        amount: 50.0,
        status: PaymentStatus.pending,
      );
      await provider.recordPayment(payment);

      await provider.updatePaymentStatus('1', PaymentStatus.completed);

      expect(provider.payments.first.status, PaymentStatus.completed);
      expect(provider.error, isNull);
    });

    test('revenueCurrency uses most frequent completed currency', () async {
      Payment build(String id, String currency) => Payment(
            id: id,
            appointmentId: 'a-$id',
            customerId: 'c',
            customerName: 'A',
            customerPhone: '',
            customerEmail: '',
            professionalId: 'p-1',
            professionalName: 'B',
            professionalPhone: '',
            professionalEmail: '',
            service: 'S',
            staffCategory: '',
            appointmentDate: DateTime.now(),
            appointmentTime: '',
            appointmentDurationMinutes: 60,
            amount: 10.0,
            currency: currency,
            status: PaymentStatus.completed,
          );

      await provider.recordPayment(build('1', 'USD'));
      await provider.recordPayment(build('2', 'EUR'));
      await provider.recordPayment(build('3', 'USD'));

      expect(provider.revenueCurrency, 'USD');
    });

    test('revenueCurrency falls back to EUR with no completed payments', () {
      expect(provider.revenueCurrency, 'EUR');
    });

    test('totalRevenue counts collected cash for deposits', () async {
      final payment = Payment(
        id: '1',
        appointmentId: 'a-1',
        customerId: 'c-1',
        customerName: 'A',
        customerPhone: '',
        customerEmail: '',
        professionalId: 'p-1',
        professionalName: 'B',
        professionalPhone: '',
        professionalEmail: '',
        service: 'S',
        staffCategory: '',
        appointmentDate: DateTime.now(),
        appointmentTime: '',
        appointmentDurationMinutes: 60,
        amount: 100.0,
        depositAmount: 30.0,
        status: PaymentStatus.completed,
      );
      await provider.recordPayment(payment);

      expect(provider.totalRevenue, 30.0);
    });

    test('recordPayment returns id and never mutates input', () async {
      final payment = Payment(
        appointmentId: 'a-9',
        customerId: 'c-9',
        customerName: 'A',
        customerPhone: '',
        customerEmail: '',
        professionalId: 'p-9',
        professionalName: 'B',
        professionalPhone: '',
        professionalEmail: '',
        service: 'S',
        staffCategory: '',
        appointmentDate: DateTime.now(),
        appointmentTime: '',
        appointmentDurationMinutes: 60,
        amount: 25.0,
        depositAmount: 5.0,
      );

      final id = await provider.recordPayment(payment);

      expect(id, isNotEmpty);
      expect(payment.id, isNull);
      expect(provider.payments.single.id, id);
      expect(provider.payments.single.depositAmount, 5.0);
      expect(provider.payments.single.balanceDue, 20.0);
    });

    test('selectPayment sets selectedPayment and notifies', () {
      final payment = Payment(
        id: '1',
        appointmentId: 'a-1',
        customerId: 'c-1',
        customerName: 'A',
        customerPhone: '',
        customerEmail: '',
        professionalId: 'p-1',
        professionalName: 'B',
        professionalPhone: '',
        professionalEmail: '',
        service: 'S',
        staffCategory: '',
        appointmentDate: DateTime.now(),
        appointmentTime: '',
        appointmentDurationMinutes: 60,
        amount: 50.0,
        status: PaymentStatus.completed,
      );

      provider.selectPayment(payment);
      expect(provider.selectedPayment, payment);

      provider.selectPayment(null);
      expect(provider.selectedPayment, isNull);
    });
  });
}
