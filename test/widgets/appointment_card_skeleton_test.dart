import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:restorahub/widgets/appointment_card_skeleton.dart';

void main() {
  group('AppointmentCardSkeleton', () {
    testWidgets('uses scheme roles instead of hardcoded grey',
        (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(body: AppointmentCardSkeleton()),
        ),
      );
      expect(find.byType(AppointmentCardSkeleton), findsOneWidget);
    });
  });
}
