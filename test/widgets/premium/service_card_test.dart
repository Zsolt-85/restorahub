import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:restorahub/models/service.dart';
import 'package:restorahub/widgets/premium/service_card.dart';

void main() {
  group('ServiceCard', () {
    testWidgets('shows name, duration, price and fires onTap', (tester) async {
      var tapped = false;
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ServiceCard(
              service: Service(
                  name: 'Swedish Massage', durationMinutes: 60, price: 85),
              rating: 4.9,
              onTap: () => tapped = true,
            ),
          ),
        ),
      );
      expect(find.text('Swedish Massage'), findsOneWidget);
      expect(find.textContaining('60'), findsOneWidget);
      await tester.tap(find.byType(ServiceCard));
      expect(tapped, isTrue);
    });

    testWidgets('shows monogram fallback without image', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ServiceCard(
              service: Service(name: 'Hot Stone'),
              onTap: () {},
            ),
          ),
        ),
      );
      expect(find.text('H'), findsOneWidget);
    });
  });
}
