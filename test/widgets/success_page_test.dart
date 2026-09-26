import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:restorahub/constants/routes.dart';
import 'package:restorahub/models/appointment.dart';
import 'package:restorahub/models/booking_summary.dart';
import 'package:restorahub/pages/success_page.dart';
import 'package:restorahub/widgets/premium/booking_summary_card.dart';

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
    testWidgets('shows BookingSummaryCard with service and pro text',
        (tester) async {
      await _pump(tester, SuccessPage(summary: _summary(price: 50.0)));

      expect(find.byType(BookingSummaryCard), findsOneWidget);
      expect(find.textContaining('Massage'), findsWidgets);
      expect(find.textContaining('Alice'), findsWidgets);
    });

    testWidgets('shows Add to Calendar action when summary non-null',
        (tester) async {
      await _pump(tester, SuccessPage(summary: _summary(price: 50.0)));

      expect(find.text('Add to Calendar'), findsOneWidget);
    });

    testWidgets('renders null summary without crash', (tester) async {
      await _pump(tester, const SuccessPage());

      expect(find.byType(BookingSummaryCard), findsNothing);
      expect(find.text('Book another'), findsOneWidget);
    });

    testWidgets('shows price value in summary card when booking has one',
        (tester) async {
      await _pump(tester, SuccessPage(summary: _summary(price: 50.0)));

      expect(find.byType(BookingSummaryCard), findsOneWidget);
      expect(find.textContaining('50.00'), findsWidgets);
    });

    testWidgets('shows summary card even when booking has no price',
        (tester) async {
      await _pump(tester, SuccessPage(summary: _summary()));

      expect(find.byType(BookingSummaryCard), findsOneWidget);
      expect(find.textContaining('Massage'), findsWidgets);
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
