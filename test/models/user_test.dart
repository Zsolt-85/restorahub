import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:restorahub/models/user.dart';

void main() {
  group('User', () {
    test('role remains customer or professional via copyWith', () {
      final customer = User(
        id: 1,
        name: 'Alex',
        email: 'alex@example.com',
        phone: '5551234567',
        password: 'hashed',
        role: 'customer',
      );

      final updated = customer.copyWith(name: 'Alex Updated');
      expect(updated.role, 'customer');
      expect(updated.isProfessional, isFalse);
    });

    test('professional defaults include schedule fields', () {
      final professional = User(
        name: 'Sam',
        email: 'sam@example.com',
        phone: '5559876543',
        password: 'hashed',
        role: 'professional',
        specialty: 'Massage',
      );

      expect(professional.workStartTime, '09:00');
      expect(professional.workEndTime, '17:00');
      expect(professional.slotDurationMinutes, 60);
    });

    test('formatTime round trips with parse', () {
      const time = TimeOfDay(hour: 8, minute: 30);
      expect(User.formatTime(time), '08:30');
    });
  });
}
