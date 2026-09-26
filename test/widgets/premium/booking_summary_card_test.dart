import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:restorahub/models/booking_summary.dart';
import 'package:restorahub/widgets/premium/booking_summary_card.dart';

void main() {
  group('BookingSummaryCard', () {
    testWidgets('shows service, pro, time and total rows', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: BookingSummaryCard(
              summary: BookingSummary(
                service: 'Swedish Massage',
                price: 85,
                professionalName: 'Elena',
                dateTime: DateTime(2026, 10, 1, 10, 30),
                durationMinutes: 60,
              ),
            ),
          ),
        ),
      );
      expect(find.textContaining('Swedish Massage'), findsOneWidget);
      expect(find.textContaining('Elena'), findsOneWidget);
      expect(find.text('Total'), findsOneWidget);
    });
  });
}
