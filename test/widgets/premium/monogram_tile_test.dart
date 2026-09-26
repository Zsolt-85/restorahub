import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:restorahub/widgets/premium/monogram_tile.dart';

void main() {
  group('MonogramTile', () {
    testWidgets('shows first initial of label', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(home: Scaffold(body: MonogramTile(label: 'Elena'))),
      );
      expect(find.text('E'), findsOneWidget);
    });

    testWidgets('shows ? for empty label', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(home: Scaffold(body: MonogramTile(label: ''))),
      );
      expect(find.text('?'), findsOneWidget);
    });
  });
}
