import 'package:flutter_test/flutter_test.dart';
import 'package:restorahub/models/business.dart';
import 'package:restorahub/models/plan.dart';
import 'package:restorahub/helpers/feature_gate.dart';
import 'package:restorahub/helpers/business_lifecycle_helper.dart';

void main() {
  group('Smoke Test — End-to-End Business Lifecycle', () {
    test('creates trial business with default entitlements', () {
      final now = DateTime.now();
      final business = Business(
        id: 'biz_1',
        name: 'RESTORE by MAYA',
        status: BusinessStatus.trial,
        subscription: BusinessSubscription(
          plan: 'trial',
          status: 'trial',
          startDate: now,
        ),
        featureEntitlements: FeatureGate.entitlementsForPlan('trial'),
        createdAt: now,
        updatedAt: now,
      );

      expect(business.isTrial, isTrue);
      expect(business.hasFeature('online_booking'), isTrue);
      expect(business.hasFeature('analytics'), isFalse);
    });

    test('upgrades to pro plan and validates feature expansion', () {
      final business = Business(
        id: 'biz_1',
        name: 'RESTORE by MAYA',
        status: BusinessStatus.active,
        featureEntitlements: FeatureGate.entitlementsForPlan('pro'),
      );

      expect(business.isActive, isTrue);
      expect(business.hasFeature('online_booking'), isTrue);
      expect(business.hasFeature('custom_branding'), isTrue);
      expect(business.hasFeature('multi_location'), isTrue);
      expect(business.hasFeature('api_access'), isFalse);
    });

    test('downgrades plan and removes premium features', () {
      final business = Business(
        id: 'biz_1',
        name: 'RESTORE by MAYA',
        featureEntitlements: FeatureGate.entitlementsForPlan('basic'),
      );

      expect(business.hasFeature('analytics'), isTrue);
      expect(business.hasFeature('custom_branding'), isFalse);
      expect(business.hasFeature('multi_location'), isFalse);
    });

    test('business lifecycle state machine transitions', () {
      final business = Business(id: 'biz_1', name: 'Test');

      expect(() => BusinessLifecycleHelper.validateTransition(business, BusinessStatus.active),
          returnsNormally);
      expect(() => BusinessLifecycleHelper.validateTransition(business, BusinessStatus.archived),
          throwsA(isA<Exception>()));
    });

    test('plan roundtrip preserves features', () {
      final plan = PlanDefinitions.byId('enterprise')!;
      final restored = Plan.fromMap(plan.toMap());

      expect(restored.id, plan.id);
      expect(restored.features, plan.features);
      expect(restored.hasFeature('api_access'), isTrue);
    });
  });
}
