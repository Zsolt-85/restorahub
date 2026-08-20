import 'package:flutter_test/flutter_test.dart';
import 'package:restorahub/models/payment.dart';
import 'package:restorahub/providers/payment_provider.dart';
import 'package:restorahub/repositories/payment_repository.dart';

class FakePaymentRepository implements PaymentRepository {
  final List<Payment> payments = [];

  @override
  Future<Payment?> getPaymentByAppointment(String appointmentId) async {
    final list = payments.where((p) => p.appointmentId == appointmentId);
    return list.isNotEmpty ? list.first : null;
  }

  @override
  Future<List<Payment>> getPaymentsByProfessional(String professionalId, {String? businessId}) async {
    return payments.where((p) => p.professionalId == professionalId).toList();
  }

  @override
  Future<List<Payment>> getPaymentsByProfessionalInRange(
    String professionalId,
    DateTime start,
    DateTime end,
    {String? businessId}
  ) async {
    return payments.where((p) {
      if (p.professionalId != professionalId && professionalId.isNotEmpty) {
        return false;
      }
      return p.appointmentDate.isAfter(start.subtract(const Duration(seconds: 1))) &&
          p.appointmentDate.isBefore(end.add(const Duration(seconds: 1)));
    }).toList();
  }

  @override
  Future<int> recordPayment(Payment payment) async {
      payment.id ??= 'PAY-${payments.length + 1}';
    payments.add(payment);
    return 1;
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
  Future<int> updatePaymentStatus(String paymentId, PaymentStatus status) async {
    final idx = payments.indexWhere((p) => p.id == paymentId);
    if (idx != -1) {
      payments[idx].status = status;
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

    test('recordPayment adds a payment to the list and updates revenue', () async {
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
        specialty: '',
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

    test('totalRevenue and completedCount only count completed payments', () async {
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
        specialty: '',
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
        specialty: '',
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
        specialty: '',
        appointmentDate: DateTime.now(),
        appointmentTime: '',
        appointmentDurationMinutes: 60,
        amount: 50.0,
        status: PaymentStatus.pending,
      );
      await provider.recordPayment(p1);

      final updated = p1.copyWith(status: PaymentStatus.completed, amount: 60.0);
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
        specialty: '',
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
        specialty: '',
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
        specialty: '',
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
