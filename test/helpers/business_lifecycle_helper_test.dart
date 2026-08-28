import 'package:flutter_test/flutter_test.dart';
import 'package:restorahub/helpers/business_lifecycle_helper.dart';
import 'package:restorahub/models/business.dart';

void main() {
  group('BusinessLifecycleHelper', () {
    test('trial can transition to active', () {
      expect(BusinessLifecycleHelper.canTransitionTo(BusinessStatus.trial, BusinessStatus.active), isTrue);
    });

    test('trial can transition to cancelled', () {
      expect(BusinessLifecycleHelper.canTransitionTo(BusinessStatus.trial, BusinessStatus.cancelled), isTrue);
    });

    test('trial cannot transition to suspended', () {
      expect(BusinessLifecycleHelper.canTransitionTo(BusinessStatus.trial, BusinessStatus.suspended), isFalse);
    });

    test('trial cannot transition to archived', () {
      expect(BusinessLifecycleHelper.canTransitionTo(BusinessStatus.trial, BusinessStatus.archived), isFalse);
    });

    test('active can transition to suspended', () {
      expect(BusinessLifecycleHelper.canTransitionTo(BusinessStatus.active, BusinessStatus.suspended), isTrue);
    });

    test('active can transition to cancelled', () {
      expect(BusinessLifecycleHelper.canTransitionTo(BusinessStatus.active, BusinessStatus.cancelled), isTrue);
    });

    test('active cannot transition to trial', () {
      expect(BusinessLifecycleHelper.canTransitionTo(BusinessStatus.active, BusinessStatus.trial), isFalse);
    });

    test('suspended can transition to active', () {
      expect(BusinessLifecycleHelper.canTransitionTo(BusinessStatus.suspended, BusinessStatus.active), isTrue);
    });

    test('suspended can transition to cancelled', () {
      expect(BusinessLifecycleHelper.canTransitionTo(BusinessStatus.suspended, BusinessStatus.cancelled), isTrue);
    });

    test('cancelled can transition to archived', () {
      expect(BusinessLifecycleHelper.canTransitionTo(BusinessStatus.cancelled, BusinessStatus.archived), isTrue);
    });

    test('cancelled cannot transition to active', () {
      expect(BusinessLifecycleHelper.canTransitionTo(BusinessStatus.cancelled, BusinessStatus.active), isFalse);
    });

    test('archived cannot transition to any status', () {
      expect(BusinessLifecycleHelper.canTransitionTo(BusinessStatus.archived, BusinessStatus.trial), isFalse);
      expect(BusinessLifecycleHelper.canTransitionTo(BusinessStatus.archived, BusinessStatus.active), isFalse);
      expect(BusinessLifecycleHelper.canTransitionTo(BusinessStatus.archived, BusinessStatus.suspended), isFalse);
      expect(BusinessLifecycleHelper.canTransitionTo(BusinessStatus.archived, BusinessStatus.cancelled), isFalse);
    });
  });

  group('BusinessLifecycleHelper.validateTransition', () {
    test('valid transition returns updated business', () {
      final business = Business(id: '1', name: 'Test', status: BusinessStatus.trial);
      final updated = BusinessLifecycleHelper.validateTransition(business, BusinessStatus.active);
      expect(updated.status, BusinessStatus.active);
    });

    test('invalid transition throws BusinessLifecycleException', () {
      final business = Business(id: '1', name: 'Test', status: BusinessStatus.archived);
      expect(
        () => BusinessLifecycleHelper.validateTransition(business, BusinessStatus.active),
        throwsA(isA<BusinessLifecycleException>()),
      );
    });
  });

  group('BusinessLifecycleHelper.allowedTransitions', () {
    test('returns correct allowed transitions for trial', () {
      final allowed = BusinessLifecycleHelper.allowedTransitions(BusinessStatus.trial);
      expect(allowed, contains(BusinessStatus.active));
      expect(allowed, contains(BusinessStatus.cancelled));
      expect(allowed.length, 2);
    });

    test('returns empty list for archived', () {
      final allowed = BusinessLifecycleHelper.allowedTransitions(BusinessStatus.archived);
      expect(allowed, isEmpty);
    });
  });

  group('BusinessLifecycleHelper convenience methods', () {
    test('canActivate returns true for trial business', () {
      final business = Business(id: '1', name: 'Test', status: BusinessStatus.trial);
      expect(BusinessLifecycleHelper.canActivate(business), isTrue);
    });

    test('canSuspend returns true for active business', () {
      final business = Business(id: '1', name: 'Test', status: BusinessStatus.active);
      expect(BusinessLifecycleHelper.canSuspend(business), isTrue);
    });

    test('canCancel returns true for active business', () {
      final business = Business(id: '1', name: 'Test', status: BusinessStatus.active);
      expect(BusinessLifecycleHelper.canCancel(business), isTrue);
    });

    test('canArchive returns true for cancelled business', () {
      final business = Business(id: '1', name: 'Test', status: BusinessStatus.cancelled);
      expect(BusinessLifecycleHelper.canArchive(business), isTrue);
    });

    test('canActivate returns false for archived business', () {
      final business = Business(id: '1', name: 'Test', status: BusinessStatus.archived);
      expect(BusinessLifecycleHelper.canActivate(business), isFalse);
    });
  });

  group('Business status getters', () {
    test('trial business isTrial returns true', () {
      final business = Business(id: '1', name: 'Test', status: BusinessStatus.trial);
      expect(business.isTrial, isTrue);
      expect(business.isActive, isFalse);
      expect(business.isSuspended, isFalse);
    });

    test('active business isActive returns true', () {
      final business = Business(id: '1', name: 'Test', status: BusinessStatus.active);
      expect(business.isActive, isTrue);
      expect(business.isTrial, isFalse);
    });

    test('suspended business isSuspended returns true', () {
      final business = Business(id: '1', name: 'Test', status: BusinessStatus.suspended);
      expect(business.isSuspended, isTrue);
      expect(business.isActive, isFalse);
    });
  });
}
