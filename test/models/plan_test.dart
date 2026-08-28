import 'package:flutter_test/flutter_test.dart';
import 'package:restorahub/models/plan.dart';

void main() {
  group('Plan', () {
    test('constructor sets fields', () {
      final plan = Plan(id: 'basic', name: 'Basic', features: ['a', 'b']);

      expect(plan.id, 'basic');
      expect(plan.name, 'Basic');
      expect(plan.features, ['a', 'b']);
    });

    test('fromMap parses fields', () {
      final map = {'id': 'pro', 'name': 'Pro', 'features': ['x', 'y']};

      final plan = Plan.fromMap(map);

      expect(plan.id, 'pro');
      expect(plan.name, 'Pro');
      expect(plan.features, ['x', 'y']);
    });

    test('fromMap defaults missing fields', () {
      final plan = Plan.fromMap({});

      expect(plan.id, '');
      expect(plan.name, '');
      expect(plan.features, isEmpty);
    });

    test('toMap serializes fields', () {
      final plan = Plan(id: 'trial', name: 'Trial', features: ['f1']);

      final map = plan.toMap();

      expect(map['id'], 'trial');
      expect(map['name'], 'Trial');
      expect(map['features'], ['f1']);
    });

    test('toMap and fromMap roundtrip', () {
      final plan = Plan(id: 'enterprise', name: 'Enterprise', features: ['a', 'b', 'c']);

      final restored = Plan.fromMap(plan.toMap());

      expect(restored.id, plan.id);
      expect(restored.name, plan.name);
      expect(restored.features, plan.features);
    });

    test('copyWith preserves fields on partial update', () {
      final plan = Plan(id: 'basic', name: 'Basic', features: ['a']);

      final updated = plan.copyWith(name: 'Basic+');

      expect(updated.id, 'basic');
      expect(updated.name, 'Basic+');
      expect(updated.features, ['a']);
    });

    test('hasFeature checks features list', () {
      final plan = Plan(id: 'pro', name: 'Pro', features: ['analytics', 'api']);

      expect(plan.hasFeature('analytics'), isTrue);
      expect(plan.hasFeature('api'), isTrue);
      expect(plan.hasFeature('unknown'), isFalse);
    });
  });

  group('PlanDefinitions', () {
    test('values contains all plans', () {
      expect(PlanDefinitions.values.length, 4);
      expect(PlanDefinitions.values.map((p) => p.id), containsAll(['trial', 'basic', 'pro', 'enterprise']));
    });

    test('byId returns correct plan', () {
      expect(PlanDefinitions.byId('basic')?.name, 'Basic');
      expect(PlanDefinitions.byId('enterprise')?.name, 'Enterprise');
    });

    test('byId returns null for unknown id', () {
      expect(PlanDefinitions.byId('unknown'), isNull);
    });

    test('featuresForPlan returns features', () {
      expect(PlanDefinitions.featuresForPlan('trial'), contains('online_booking'));
      expect(PlanDefinitions.featuresForPlan('pro'), contains('custom_branding'));
    });

    test('featuresForPlan returns empty for unknown id', () {
      expect(PlanDefinitions.featuresForPlan('missing'), isEmpty);
    });
  });
}
