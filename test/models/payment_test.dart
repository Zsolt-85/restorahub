import 'package:flutter_test/flutter_test.dart';
import 'package:restorahub/models/payment.dart';

Payment _payment() => Payment(
      id: 'pay-1',
      appointmentId: 'a1',
      customerId: 'cust-1',
      customerName: 'Customer',
      customerPhone: '555-0100',
      customerEmail: 'cust@test.com',
      professionalId: 'prof-1',
      professionalName: 'Professional',
      professionalPhone: '555-0200',
      professionalEmail: 'prof@test.com',
      service: 'Massage',
      staffCategory: 'massage',
      businessId: 'biz-1',
      appointmentDate: DateTime(2030, 5, 1, 10, 0),
      appointmentTime: '10:00',
      appointmentDurationMinutes: 60,
      amount: 100.0,
      depositAmount: 30.0,
      noShowFee: 15.0,
    );

void main() {
  group('Payment', () {
    test('defaults are safe for new payments', () {
      final payment = Payment(
        appointmentId: 'a1',
        customerId: 'c',
        customerName: 'C',
        customerPhone: '',
        customerEmail: '',
        professionalId: 'p',
        professionalName: 'P',
        professionalPhone: '',
        professionalEmail: '',
        service: 'S',
        staffCategory: '',
        appointmentDate: DateTime(2030, 5, 1),
        appointmentTime: '10:00',
        appointmentDurationMinutes: 60,
        amount: 50.0,
      );

      expect(payment.currency, 'EUR');
      expect(payment.method, PaymentMethod.cash);
      expect(payment.status, PaymentStatus.pending);
      expect(payment.depositAmount, 0.0);
      expect(payment.noShowFee, 0.0);
      expect(payment.balanceDue, 50.0);
    });

    test('balanceDue subtracts deposit and never goes negative', () {
      expect(_payment().balanceDue, 70.0);
      expect(_payment().copyWith(depositAmount: 150.0).balanceDue, 0.0);
    });

    test('fromMap/toMap round-trip preserves tenant and money fields', () {
      final restored = Payment.fromMap(_payment().toMap());

      expect(restored.id, 'pay-1');
      expect(restored.businessId, 'biz-1');
      expect(restored.amount, 100.0);
      expect(restored.depositAmount, 30.0);
      expect(restored.noShowFee, 15.0);
      expect(restored.currency, 'EUR');
      expect(restored.method, PaymentMethod.cash);
      expect(restored.status, PaymentStatus.pending);
    });

    test('fromMap is backward compatible with legacy documents', () {
      final legacy = Payment.fromMap({
        'appointmentId': 'a1',
        'amount': 40,
        'staffCategory': '',
        'appointmentDate': '2030-05-01T10:00:00.000',
      });

      expect(legacy.businessId, isNull);
      expect(legacy.depositAmount, 0.0);
      expect(legacy.noShowFee, 0.0);
      expect(legacy.balanceDue, 40.0);
      // Legacy dual-write: specialty resolves into staffCategory.
      expect(legacy.staffCategory, '');
    });

    test('fromMap resolves legacy specialty into staffCategory', () {
      final legacy = Payment.fromMap({
        'appointmentId': 'a1',
        'specialty': 'massage',
        'amount': 40,
        'appointmentDate': '2030-05-01T10:00:00.000',
      });

      expect(legacy.staffCategory, 'massage');
    });

    test('copyWith creates modified copies incl. money fields', () {
      final updated = _payment().copyWith(
        status: PaymentStatus.refunded,
        depositAmount: 50.0,
      );

      expect(updated.status, PaymentStatus.refunded);
      expect(updated.depositAmount, 50.0);
      expect(updated.balanceDue, 50.0);
      expect(updated.id, 'pay-1');
    });

    test('status labels cover the refund path', () {
      expect(_payment().copyWith(status: PaymentStatus.refunded).statusLabel,
          'Refunded');
    });
  });
}
