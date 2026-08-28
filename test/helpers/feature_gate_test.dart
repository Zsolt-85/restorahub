import 'package:flutter_test/flutter_test.dart';
import 'package:restorahub/helpers/feature_gate.dart';
import 'package:restorahub/models/business.dart';

void main() {
  group('FeatureGate', () {
    test('isAvailable returns true when business has feature', () {
      final business = Business(
        id: 'biz_1',
        name: 'Test',
        featureEntitlements: ['online_booking', 'analytics'],
      );

      expect(FeatureGate.isAvailable(business, 'online_booking'), isTrue);
      expect(FeatureGate.isAvailable(business, 'analytics'), isTrue);
    });

    test('isAvailable returns false when business lacks feature', () {
      final business = Business(
        id: 'biz_1',
        name: 'Test',
        featureEntitlements: ['online_booking'],
      );

      expect(FeatureGate.isAvailable(business, 'analytics'), isFalse);
    });

    test('isAvailable returns false for empty entitlements', () {
      final business = Business(
        id: 'biz_1',
        name: 'Test',
      );

      expect(FeatureGate.isAvailable(business, 'online_booking'), isFalse);
    });

    test('isAvailableForPlan checks plan features', () {
      expect(FeatureGate.isAvailableForPlan('pro', 'custom_branding'), isTrue);
      expect(FeatureGate.isAvailableForPlan('basic', 'custom_branding'), isFalse);
      expect(FeatureGate.isAvailableForPlan('unknown', 'anything'), isFalse);
    });

    test('entitlementsForPlan returns plan features', () {
      expect(FeatureGate.entitlementsForPlan('trial'), contains('online_booking'));
      expect(FeatureGate.entitlementsForPlan('enterprise'), contains('api_access'));
    });

    test('entitlementsForPlan returns empty for unknown plan', () {
      expect(FeatureGate.entitlementsForPlan('missing'), isEmpty);
    });
  });
}
