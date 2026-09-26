import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:restorahub/models/business.dart';
import 'package:restorahub/providers/business_provider.dart';
import 'package:restorahub/widgets/premium/tenant_hero.dart';

Business _business({String? logoUrl}) => Business(
      id: 'b1',
      name: 'Restore by Maya',
      logoUrl: logoUrl,
      address: 'Main St 12',
    );

void main() {
  group('TenantHero', () {
    testWidgets('falls back to RestoraHub without business', (tester) async {
      final provider = BusinessProvider();
      await tester.pumpWidget(
        MaterialApp(
          home: ChangeNotifierProvider<BusinessProvider>.value(
            value: provider,
            child: const Scaffold(body: TenantHero()),
          ),
        ),
      );
      expect(find.text('RestoraHub'), findsOneWidget);
    });

    testWidgets('shows business name and monogram without logo',
        (tester) async {
      final provider = BusinessProvider();
      provider.setBusiness(_business());
      await tester.pumpWidget(
        MaterialApp(
          home: ChangeNotifierProvider<BusinessProvider>.value(
            value: provider,
            child: const Scaffold(body: TenantHero()),
          ),
        ),
      );
      expect(find.text('Restore by Maya'), findsOneWidget);
      expect(find.text('R'), findsOneWidget);
    });
  });
}
