import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:restorahub/widgets/premium/app_error_banner.dart';

void main() {
  group('AppErrorBanner', () {
    testWidgets('shows icon, message and retry', (tester) async {
      var retried = false;
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: AppErrorBanner(
              message: 'Could not load',
              onRetry: () => retried = true,
            ),
          ),
        ),
      );
      expect(find.text('Could not load'), findsOneWidget);
      expect(find.byIcon(Icons.error_outline), findsOneWidget);
      await tester.tap(find.text('Retry'));
      expect(retried, isTrue);
    });

    testWidgets('no retry button when onRetry is null', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(body: AppErrorBanner(message: 'Oops')),
        ),
      );
      expect(find.text('Retry'), findsNothing);
    });
  });
}
