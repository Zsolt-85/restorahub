import 'package:flutter_test/flutter_test.dart';
import 'package:restorahub/models/business.dart';
import 'package:restorahub/models/location.dart';
import 'package:restorahub/providers/business_provider.dart';

void main() {
  group('BusinessProvider', () {
    test('setBusiness sets current business and active location', () {
      final provider = BusinessProvider();
      final business = Business(
        id: 'biz_1',
        name: 'Test',
        locations: [Location(id: 'loc_1', name: 'Main')],
        activeLocationId: 'loc_1',
      );

      provider.setBusiness(business);

      expect(provider.currentBusiness, business);
      expect(provider.activeLocation?.id, 'loc_1');
      expect(provider.activeLocation?.name, 'Main');
    });

    test('setBusiness defaults active location to first location', () {
      final provider = BusinessProvider();
      final business = Business(
        id: 'biz_1',
        name: 'Test',
        locations: [
          Location(id: 'loc_1', name: 'Main'),
          Location(id: 'loc_2', name: 'Branch'),
        ],
      );

      provider.setBusiness(business);

      expect(provider.activeLocation?.id, 'loc_1');
    });

    test('setActiveLocation changes active location', () {
      final provider = BusinessProvider();
      final business = Business(
        id: 'biz_1',
        name: 'Test',
        locations: [
          Location(id: 'loc_1', name: 'Main'),
          Location(id: 'loc_2', name: 'Branch'),
        ],
      );

      provider.setBusiness(business);
      provider.setActiveLocation('loc_2');

      expect(provider.activeLocation?.id, 'loc_2');
      expect(provider.activeLocation?.name, 'Branch');
    });

    test('clearBusiness resets state', () {
      final provider = BusinessProvider();
      final business = Business(
        id: 'biz_1',
        name: 'Test',
        locations: [Location(id: 'loc_1', name: 'Main')],
      );

      provider.setBusiness(business);
      provider.clearBusiness();

      expect(provider.currentBusiness, isNull);
      expect(provider.activeLocation, isNull);
    });

    test('activeLocation returns null when no business', () {
      final provider = BusinessProvider();
      expect(provider.activeLocation, isNull);
    });

    test('activeLocation returns null when location not found', () {
      final provider = BusinessProvider();
      final business = Business(
        id: 'biz_1',
        name: 'Test',
        locations: [Location(id: 'loc_1', name: 'Main')],
        activeLocationId: 'loc_missing',
      );

      provider.setBusiness(business);

      expect(provider.activeLocation?.id, 'loc_1');
    });
  });
}
