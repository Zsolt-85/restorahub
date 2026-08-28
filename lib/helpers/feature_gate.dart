import 'package:restorahub/models/business.dart';
import 'package:restorahub/models/plan.dart';

class FeatureGate {
  static bool isAvailable(Business business, String feature) {
    return business.hasFeature(feature);
  }

  static bool isAvailableForPlan(String planId, String feature) {
    return PlanDefinitions.byId(planId)?.hasFeature(feature) ?? false;
  }

  static List<String> entitlementsForPlan(String planId) {
    return PlanDefinitions.featuresForPlan(planId);
  }
}
