import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:restorahub/widgets/premium/wizard_shell.dart';

void main() {
  group('WizardShell', () {
    testWidgets('renders one segment per step and footer', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: WizardShell(
            currentStep: 1,
            totalSteps: 4,
            title: 'Book',
            footer: const Text('Next'),
            onBack: () {},
            child: const Text('Body'),
          ),
        ),
      );
      expect(find.text('Book'), findsOneWidget);
      expect(find.text('Next'), findsOneWidget);
      expect(find.text('Body'), findsOneWidget);
    });

    testWidgets('back button is absent without onBack', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: WizardShell(
            currentStep: 0,
            totalSteps: 4,
            title: 'Book',
            child: Text('Body'),
          ),
        ),
      );
      expect(find.byIcon(Icons.arrow_back), findsNothing);
    });
  });
}
