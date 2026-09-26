import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:restorahub/widgets/premium/pro_profile_header.dart';

void main() {
  group('ProProfileHeader', () {
    testWidgets('shows name and monogram fallback without photo',
        (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: ProProfileHeader(name: 'Elena', specialty: 'Massage'),
          ),
        ),
      );
      expect(find.text('Elena'), findsOneWidget);
      expect(find.text('E'), findsOneWidget);
    });

    testWidgets('selected state shows check affordance', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: ProProfileHeader(name: 'Elena', selected: true),
          ),
        ),
      );
      expect(find.byIcon(Icons.check), findsOneWidget);
    });
  });
}
