class Plan {
  final String id;
  final String name;
  final List<String> features;

  Plan({
    required this.id,
    required this.name,
    required this.features,
  });

  factory Plan.fromMap(Map<String, dynamic> map) {
    return Plan(
      id: map['id']?.toString() ?? '',
      name: map['name']?.toString() ?? '',
      features: map['features'] != null
          ? List<String>.from((map['features'] as List<dynamic>).map((e) => e.toString()))
          : const [],
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'features': features,
    };
  }

  Plan copyWith({
    String? id,
    String? name,
    List<String>? features,
  }) {
    return Plan(
      id: id ?? this.id,
      name: name ?? this.name,
      features: features ?? this.features,
    );
  }

  bool hasFeature(String feature) => features.contains(feature);
}

class PlanDefinitions {
  static final trial = Plan(
    id: 'trial',
    name: 'Trial',
    features: [
      'online_booking',
      'staff_management',
      'service_management',
      'notifications',
    ],
  );

  static final basic = Plan(
    id: 'basic',
    name: 'Basic',
    features: [
      'online_booking',
      'staff_management',
      'service_management',
      'notifications',
      'analytics',
    ],
  );

  static final pro = Plan(
    id: 'pro',
    name: 'Pro',
    features: [
      'online_booking',
      'staff_management',
      'service_management',
      'notifications',
      'analytics',
      'custom_branding',
      'multi_location',
    ],
  );

  static final enterprise = Plan(
    id: 'enterprise',
    name: 'Enterprise',
    features: [
      'online_booking',
      'staff_management',
      'service_management',
      'notifications',
      'analytics',
      'custom_branding',
      'multi_location',
      'api_access',
    ],
  );

  static List<Plan> get values => [trial, basic, pro, enterprise];

  static Plan? byId(String id) {
    for (final plan in values) {
      if (plan.id == id) return plan;
    }
    return null;
  }

  static List<String> featuresForPlan(String planId) {
    return byId(planId)?.features ?? const [];
  }
}
