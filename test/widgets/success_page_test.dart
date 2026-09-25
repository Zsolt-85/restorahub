import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:restorahub/constants/routes.dart';
import 'package:restorahub/models/appointment.dart';
import 'package:restorahub/models/booking_summary.dart';
import 'package:restorahub/pages/success_page.dart';

BookingSummary _summary({double? price}) => BookingSummary(
      service: 'Massage',
      price: price,
      professionalName: 'Alice',
      professionalId: 'p1',
      dateTime: DateTime(2030, 5, 1, 10, 0),
      durationMinutes: 60,
      status: AppointmentStatus.pending,
    );

Future<void> _pump(WidgetTester tester, Widget home,
    {Map<String, WidgetBuilder>? routes}) async {
  tester.view.physicalSize = const Size(1080, 2400);
  tester.view.devicePixelRatio = 1.0;
  addTearDown(tester.view.resetPhysicalSize);
  await tester.pumpWidget(MaterialApp(home: home, routes: routes ?? {}));
}

void main() {
  group('SuccessPage', () {
    testWidgets('shows price when the booking has one', (tester) async {
      await _pump(tester, SuccessPage(summary: _summary(price: 50.0)));

      expect(find.text('Price'), findsOneWidget);
      expect(find.textContaining('50.00'), findsOneWidget);
    });

    testWidgets('omits price row when the booking has none', (tester) async {
      await _pump(tester, SuccessPage(summary: _summary()));

      expect(find.text('Price'), findsNothing);
    });

    testWidgets('Book another returns to services', (tester) async {
      await _pump(
        tester,
        SuccessPage(summary: _summary(price: 50.0)),
        routes: {
          Routes.services: (_) => const Scaffold(body: Text('services-dest')),
        },
      );

      await tester.tap(find.text('Book another'));
      await tester.pumpAndSettle();

      expect(find.text('services-dest'), findsOneWidget);
    });
  });
}
