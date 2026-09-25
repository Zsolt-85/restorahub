import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:restorahub/models/appointment.dart';
import 'package:restorahub/widgets/appointment_card.dart';

Appointment _appointment(
        {AppointmentStatus status = AppointmentStatus.completed,
        String? paymentId}) =>
    Appointment(
      id: 'a1',
      service: 'Massage',
      dateTime: DateTime.now().subtract(const Duration(days: 1)),
      durationMinutes: 60,
      status: status,
      customerId: 'cust-1',
      customerName: 'Customer',
      professionalId: 'prof-1',
      professionalName: 'Pro',
      paymentId: paymentId,
    );

void main() {
  group('AppointmentCard record payment entry', () {
    testWidgets('shows Record payment for unpaid completed bookings',
        (tester) async {
      var tapped = false;
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: AppointmentCard(
              appointment: _appointment(),
              viewerIsCustomer: false,
              onCancel: () {},
              onPay: (_) => tapped = true,
            ),
          ),
        ),
      );

      await tester.tap(find.text('Record payment'));
      await tester.pumpAndSettle();

      expect(tapped, isTrue);
    });

    testWidgets('hides Record payment once paid', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: AppointmentCard(
              appointment: _appointment(paymentId: 'pay-1'),
              viewerIsCustomer: false,
              onCancel: () {},
              onPay: (_) {},
            ),
          ),
        ),
      );

      expect(find.text('Record payment'), findsNothing);
    });

    testWidgets('hides Record payment from customers', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: AppointmentCard(
              appointment: _appointment(),
              viewerIsCustomer: true,
              onCancel: () {},
              onPay: (_) {},
            ),
          ),
        ),
      );

      expect(find.text('Record payment'), findsNothing);
    });
  });
}
