import '../models/business.dart';

class BusinessLifecycleException implements Exception {
  final String message;
  BusinessLifecycleException(this.message);

  @override
  String toString() => message;
}

class BusinessLifecycleHelper {
  static const Map<BusinessStatus, List<BusinessStatus>> _validTransitions = {
    BusinessStatus.trial: [BusinessStatus.active, BusinessStatus.cancelled],
    BusinessStatus.active: [BusinessStatus.suspended, BusinessStatus.cancelled],
    BusinessStatus.suspended: [BusinessStatus.active, BusinessStatus.cancelled],
    BusinessStatus.cancelled: [BusinessStatus.archived],
    BusinessStatus.archived: [],
  };

  static bool canTransitionTo(BusinessStatus from, BusinessStatus to) {
    final allowed = _validTransitions[from];
    return allowed != null && allowed.contains(to);
  }

  static Business validateTransition(Business business, BusinessStatus newStatus) {
    if (!canTransitionTo(business.status, newStatus)) {
      throw BusinessLifecycleException(
        'Invalid status transition from ${business.status.name} to ${newStatus.name}',
      );
    }
    return business.copyWith(status: newStatus);
  }

  static bool get isTerminal => _validTransitions[BusinessStatus.archived]!.isEmpty;

  static List<BusinessStatus> allowedTransitions(BusinessStatus status) {
    return _validTransitions[status] ?? const [];
  }

  static bool canActivate(Business business) =>
      canTransitionTo(business.status, BusinessStatus.active);

  static bool canSuspend(Business business) =>
      canTransitionTo(business.status, BusinessStatus.suspended);

  static bool canCancel(Business business) =>
      canTransitionTo(business.status, BusinessStatus.cancelled);

  static bool canArchive(Business business) =>
      canTransitionTo(business.status, BusinessStatus.archived);
}
