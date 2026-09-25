import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:restorahub/models/business.dart';
import 'package:restorahub/models/payment.dart';
import 'package:restorahub/pages/receipt_page.dart';
import 'package:restorahub/providers/business_provider.dart';

Payment _payment({String? id, double depositAmount = 0.0}) => Payment(
      id: id,
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
      appointmentDate: DateTime(2030, 5, 1, 10, 0),
      appointmentTime: '10:00',
      appointmentDurationMinutes: 60,
      amount: 100.0,
      depositAmount: depositAmount,
      status: PaymentStatus.completed,
    );

void main() {
  group('ReceiptPage', () {
    testWidgets('short ids never throw RangeError', (tester) async {
      await tester.pumpWidget(
        MaterialApp(home: ReceiptPage(payment: _payment(id: 'PAY-1'))),
      );

      expect(find.textContaining('RCP-PAY-1'), findsWidgets);
    });

    testWidgets('long ids are truncated to 8 chars', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
            home: ReceiptPage(
                payment: _payment(id: 'abcdefghijklmnopqrstuvwxyz'))),
      );

      expect(find.textContaining('RCP-abcdefgh'), findsWidgets);
    });

    testWidgets('deposit and balance show only when a deposit exists',
        (tester) async {
      await tester.pumpWidget(
        MaterialApp(home: ReceiptPage(payment: _payment(id: 'PAY-1'))),
      );
      expect(find.text('Deposit'), findsNothing);

      await tester.pumpWidget(
        MaterialApp(
            home: ReceiptPage(
                payment: _payment(id: 'PAY-1', depositAmount: 30.0))),
      );
      await tester.pumpAndSettle();
      expect(find.text('Deposit'), findsOneWidget);
      expect(find.text('Balance due'), findsOneWidget);
    });

    testWidgets('shows the salon brand instead of the platform', (tester) async {
      final businessProvider = BusinessProvider()
        ..setBusiness(Business(id: 'biz-1', name: 'RESTORE by MAYA'));

      await tester.pumpWidget(
        MultiProvider(
          providers: [
            ChangeNotifierProvider<BusinessProvider>.value(
                value: businessProvider),
          ],
          child: MaterialApp(
              home: ReceiptPage(payment: _payment(id: 'PAY-1'))),
        ),
      );

      expect(find.text('RESTORE BY MAYA'), findsOneWidget);
      expect(find.text('RESTORAHUB'), findsNothing);
    });

    testWidgets('falls back to generic brand without a business',
        (tester) async {
      await tester.pumpWidget(
        MaterialApp(home: ReceiptPage(payment: _payment(id: 'PAY-1'))),
      );

      expect(find.text('SALON'), findsOneWidget);
    });
  });
}
