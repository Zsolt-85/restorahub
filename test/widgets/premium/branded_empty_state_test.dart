import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:restorahub/widgets/premium/branded_empty_state.dart';

void main() {
  group('BrandedEmptyState', () {
    testWidgets('shows icon, title, subtitle and fires action',
        (tester) async {
      var tapped = false;
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: BrandedEmptyState(
              icon: Icons.calendar_today,
              title: 'No appointments',
              subtitle: 'Book your first visit',
              actionButton: ElevatedButton(
                onPressed: () => tapped = true,
                child: const Text('Book now'),
              ),
            ),
          ),
        ),
      );
      expect(find.text('No appointments'), findsOneWidget);
      expect(find.text('Book your first visit'), findsOneWidget);
      expect(find.byIcon(Icons.calendar_today), findsOneWidget);
      await tester.tap(find.text('Book now'));
      expect(tapped, isTrue);
    });

    testWidgets('renders without action button', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: BrandedEmptyState(
              icon: Icons.inbox,
              title: 'Empty',
              subtitle: 'Nothing here',
            ),
          ),
        ),
      );
      expect(find.byType(ElevatedButton), findsNothing);
    });
  });
}
