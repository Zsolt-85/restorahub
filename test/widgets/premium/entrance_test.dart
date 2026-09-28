import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:restorahub/widgets/premium/entrance.dart';

void main() {
  group('Entrance', () {
    testWidgets('renders child visible', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(body: Entrance(index: 0, child: Text('Hi'))),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.text('Hi'), findsOneWidget);
    });

    testWidgets('renders instantly with animations disabled', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: MediaQuery(
              data: MediaQueryData(disableAnimations: true),
              child: Entrance(index: 3, child: Text('Hi')),
            ),
          ),
        ),
      );
      await tester.pump();
      expect(find.text('Hi'), findsOneWidget);
    });
  });
}
