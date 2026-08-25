import 'package:flutter_test/flutter_test.dart';
import 'package:restorahub/models/business.dart';

void main() {
  group('Business', () {
    test('backward compatible constructor with existing fields', () {
      final business = Business(
        id: 'biz_1',
        name: 'Test Business',
        email: 'test@business.com',
        logoUrl: 'https://example.com/logo.png',
        primaryColorHex: '#FF5733',
        phone: '5551234567',
        address: '123 Test St',
      );

      expect(business.id, 'biz_1');
      expect(business.name, 'Test Business');
      expect(business.email, 'test@business.com');
      expect(business.logoUrl, 'https://example.com/logo.png');
      expect(business.primaryColorHex, '#FF5733');
      expect(business.phone, '5551234567');
      expect(business.address, '123 Test St');
    });

    test('default status is trial', () {
      final business = Business(id: 'biz_1', name: 'Test');
      expect(business.status, BusinessStatus.trial);
      expect(business.isTrial, isTrue);
      expect(business.isActive, isFalse);
    });

    test('full constructor with all new fields', () {
      final business = Business(
        id: 'biz_1',
        name: 'Test Business',
        slug: 'test-business',
        businessType: BusinessType.wellness,
        status: BusinessStatus.active,
        ownerId: 'owner_1',
        contactInformation: BusinessContactInformation(
          address: '123 Test St',
          phone: '5551234567',
          email: 'test@business.com',
          website: 'https://test.com',
        ),
        branding: BusinessBranding(
          businessName: 'Test Brand',
          logo: 'https://test.com/logo.png',
          primaryColor: '#FF5733',
          secondaryColor: '#33FF57',
          accentColor: '#3357FF',
        ),
        settings: BusinessSettings(
          cancellationWindowHours: 24,
          bufferTimeMinutes: 15,
        ),
        subscription: BusinessSubscription(
          plan: 'starter',
          status: 'active',
        ),
        featureEntitlements: ['onlineBooking', 'notifications'],
        createdAt: DateTime(2026, 1, 1),
        updatedAt: DateTime(2026, 1, 15),
      );

      expect(business.slug, 'test-business');
      expect(business.businessType, BusinessType.wellness);
      expect(business.status, BusinessStatus.active);
      expect(business.ownerId, 'owner_1');
      expect(business.contactInformation?.website, 'https://test.com');
      expect(business.branding?.secondaryColor, '#33FF57');
      expect(business.settings?.cancellationWindowHours, 24);
      expect(business.subscription?.plan, 'starter');
      expect(business.featureEntitlements.length, 2);
      expect(business.isActive, isTrue);
      expect(business.isTrial, isFalse);
    });

    test('effective properties fall back to legacy fields', () {
      final business = Business(
        id: 'biz_1',
        name: 'Legacy Business',
        primaryColorHex: '#FF5733',
        logoUrl: 'https://legacy.com/logo.png',
      );

      expect(business.effectivePrimaryColor, '#FF5733');
      expect(business.effectiveBusinessName, 'Legacy Business');
      expect(business.effectiveLogo, 'https://legacy.com/logo.png');
    });

    test('effective properties prefer branding over legacy', () {
      final business = Business(
        id: 'biz_1',
        name: 'Legacy Business',
        primaryColorHex: '#FF5733',
        logoUrl: 'https://legacy.com/logo.png',
        branding: BusinessBranding(
          businessName: 'Branded Business',
          primaryColor: '#33FF57',
          logo: 'https://branded.com/logo.png',
        ),
      );

      expect(business.effectivePrimaryColor, '#33FF57');
      expect(business.effectiveBusinessName, 'Branded Business');
      expect(business.effectiveLogo, 'https://branded.com/logo.png');
    });

    test('hasFeature checks entitlements', () {
      final business = Business(
        id: 'biz_1',
        name: 'Test',
        featureEntitlements: ['onlineBooking', 'analytics'],
      );

      expect(business.hasFeature('onlineBooking'), isTrue);
      expect(business.hasFeature('analytics'), isTrue);
      expect(business.hasFeature('payments'), isFalse);
    });
  });

  group('Business fromMap', () {
    test('parses existing fields correctly', () {
      final map = {
        'id': 'biz_1',
        'name': 'Test Business',
        'email': 'test@business.com',
        'logoUrl': 'https://example.com/logo.png',
        'primaryColorHex': '#FF5733',
        'phone': '5551234567',
        'address': '123 Test St',
      };

      final business = Business.fromMap(map);

      expect(business.id, 'biz_1');
      expect(business.name, 'Test Business');
      expect(business.email, 'test@business.com');
    });

    test('parses new fields correctly', () {
      final map = {
        'id': 'biz_1',
        'name': 'Test Business',
        'slug': 'test-business',
        'businessType': 'wellness',
        'status': 'active',
        'ownerId': 'owner_1',
        'branding': {
          'businessName': 'Test Brand',
          'primaryColor': '#FF5733',
        },
        'contactInformation': {
          'address': '123 Test St',
          'phone': '5551234567',
        },
        'settings': {
          'cancellationWindowHours': 24,
        },
        'subscription': {
          'plan': 'starter',
          'status': 'active',
        },
        'featureEntitlements': ['onlineBooking'],
        'createdAt': '2026-01-01T00:00:00.000',
        'updatedAt': '2026-01-15T00:00:00.000',
      };

      final business = Business.fromMap(map);

      expect(business.slug, 'test-business');
      expect(business.businessType, BusinessType.wellness);
      expect(business.status, BusinessStatus.active);
      expect(business.ownerId, 'owner_1');
      expect(business.branding?.businessName, 'Test Brand');
      expect(business.settings?.cancellationWindowHours, 24);
      expect(business.subscription?.plan, 'starter');
      expect(business.featureEntitlements, ['onlineBooking']);
    });

    test('defaults status to trial for unknown values', () {
      final map = {
        'id': 'biz_1',
        'name': 'Test',
        'status': 'unknown_status',
      };

      final business = Business.fromMap(map);
      expect(business.status, BusinessStatus.trial);
    });

    test('handles missing new fields gracefully', () {
      final map = {
        'id': 'biz_1',
        'name': 'Minimal Business',
      };

      final business = Business.fromMap(map);

      expect(business.slug, isNull);
      expect(business.businessType, isNull);
      expect(business.status, BusinessStatus.trial);
      expect(business.ownerId, isNull);
      expect(business.branding, isNull);
      expect(business.settings, isNull);
      expect(business.subscription, isNull);
      expect(business.featureEntitlements, isEmpty);
    });
  });

  group('Business toMap', () {
    test('serializes all fields', () {
      final business = Business(
        id: 'biz_1',
        name: 'Test Business',
        slug: 'test-business',
        businessType: BusinessType.wellness,
        status: BusinessStatus.active,
        ownerId: 'owner_1',
        featureEntitlements: ['onlineBooking'],
        createdAt: DateTime(2026, 1, 1),
        updatedAt: DateTime(2026, 1, 15),
      );

      final map = business.toMap();

      expect(map['id'], 'biz_1');
      expect(map['name'], 'Test Business');
      expect(map['slug'], 'test-business');
      expect(map['businessType'], 'wellness');
      expect(map['status'], 'active');
      expect(map['ownerId'], 'owner_1');
      expect(map['featureEntitlements'], ['onlineBooking']);
      expect(map['createdAt'], isNotNull);
      expect(map['updatedAt'], isNotNull);
    });
  });

  group('Business copyWith', () {
    test('preserves existing fields on partial update', () {
      final original = Business(
        id: 'biz_1',
        name: 'Original',
        email: 'original@test.com',
        primaryColorHex: '#FF5733',
      );

      final updated = original.copyWith(name: 'Updated');

      expect(updated.id, 'biz_1');
      expect(updated.name, 'Updated');
      expect(updated.email, 'original@test.com');
      expect(updated.primaryColorHex, '#FF5733');
    });

    test('updates status correctly', () {
      final business = Business(id: 'biz_1', name: 'Test');
      expect(business.status, BusinessStatus.trial);

      final activated = business.copyWith(status: BusinessStatus.active);
      expect(activated.status, BusinessStatus.active);
      expect(activated.isActive, isTrue);
    });
  });

  group('BusinessBranding', () {
    test('fromMap and toMap roundtrip', () {
      final branding = BusinessBranding(
        businessName: 'Test Brand',
        primaryColor: '#FF5733',
        secondaryColor: '#33FF57',
      );

      final map = branding.toMap();
      final restored = BusinessBranding.fromMap(map);

      expect(restored.businessName, 'Test Brand');
      expect(restored.primaryColor, '#FF5733');
      expect(restored.secondaryColor, '#33FF57');
    });
  });

  group('BusinessSubscription', () {
    test('handles date serialization', () {
      final subscription = BusinessSubscription(
        plan: 'starter',
        startDate: DateTime(2026, 1, 1),
        endDate: DateTime(2026, 12, 31),
        status: 'active',
      );

      final map = subscription.toMap();
      final restored = BusinessSubscription.fromMap(map);

      expect(restored.plan, 'starter');
      expect(restored.startDate, DateTime(2026, 1, 1));
      expect(restored.endDate, DateTime(2026, 12, 31));
      expect(restored.status, 'active');
    });
  });
}
