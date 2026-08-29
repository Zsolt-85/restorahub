import 'package:flutter_test/flutter_test.dart';
import 'package:restorahub/models/location.dart';

void main() {
  group('Location', () {
    test('constructor sets fields', () {
      final location = Location(
        id: 'loc_1',
        name: 'Main Office',
        address: '123 Main St',
        phone: '5551234567',
        email: 'main@example.com',
        isActive: true,
      );

      expect(location.id, 'loc_1');
      expect(location.name, 'Main Office');
      expect(location.address, '123 Main St');
      expect(location.phone, '5551234567');
      expect(location.email, 'main@example.com');
      expect(location.isActive, isTrue);
    });

    test('default isActive is true', () {
      final location = Location(id: 'loc_1', name: 'Main Office');
      expect(location.isActive, isTrue);
    });

    test('fromMap parses fields', () {
      final map = {
        'id': 'loc_1',
        'name': 'Main Office',
        'address': '123 Main St',
        'phone': '5551234567',
        'email': 'main@example.com',
        'isActive': true,
      };

      final location = Location.fromMap(map);

      expect(location.id, 'loc_1');
      expect(location.name, 'Main Office');
      expect(location.address, '123 Main St');
      expect(location.phone, '5551234567');
      expect(location.email, 'main@example.com');
      expect(location.isActive, isTrue);
    });

    test('fromMap defaults missing fields', () {
      final map = {'name': 'Main Office'};

      final location = Location.fromMap(map);

      expect(location.id, isNull);
      expect(location.name, 'Main Office');
      expect(location.address, isNull);
      expect(location.phone, isNull);
      expect(location.email, isNull);
      expect(location.isActive, isTrue);
    });

    test('toMap serializes fields', () {
      final location = Location(
        id: 'loc_1',
        name: 'Main Office',
        address: '123 Main St',
        phone: '5551234567',
        email: 'main@example.com',
        isActive: true,
      );

      final map = location.toMap();

      expect(map['id'], 'loc_1');
      expect(map['name'], 'Main Office');
      expect(map['address'], '123 Main St');
      expect(map['phone'], '5551234567');
      expect(map['email'], 'main@example.com');
      expect(map['isActive'], isTrue);
    });

    test('toMap and fromMap roundtrip', () {
      final location = Location(
        id: 'loc_1',
        name: 'Main Office',
        address: '123 Main St',
        phone: '5551234567',
        email: 'main@example.com',
        isActive: false,
      );

      final restored = Location.fromMap(location.toMap());

      expect(restored.id, location.id);
      expect(restored.name, location.name);
      expect(restored.address, location.address);
      expect(restored.phone, location.phone);
      expect(restored.email, location.email);
      expect(restored.isActive, location.isActive);
    });

    test('copyWith preserves fields on partial update', () {
      final original = Location(
        id: 'loc_1',
        name: 'Main Office',
        address: '123 Main St',
        phone: '5551234567',
      );

      final updated = original.copyWith(name: 'Branch Office');

      expect(updated.id, 'loc_1');
      expect(updated.name, 'Branch Office');
      expect(updated.address, '123 Main St');
      expect(updated.phone, '5551234567');
    });
  });
}
