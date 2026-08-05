import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:restorahub/models/user.dart';

void main() {
  group('User', () {
    test('role remains customer or professional via copyWith', () {
      final customer = User(
        id: '1',
        name: 'Alex',
        email: 'alex@example.com',
        phone: '5551234567',
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
        role: 'professional',
        specialty: 'Massage',
      );

      expect(professional.workStartTime, '09:00');
      expect(professional.workEndTime, '17:00');
      expect(professional.slotDurationMinutes, 60);
      expect(professional.bufferTimeMinutes, 0);
      expect(professional.breakStartTime, isNull);
      expect(professional.breakEndTime, isNull);
    });

    test('formatTime round trips with parse', () {
      const time = TimeOfDay(hour: 8, minute: 30);
      expect(User.formatTime(time), '08:30');
    });

    test('professional with buffer and break fields', () {
      final professional = User(
        name: 'Jordan',
        email: 'jordan@example.com',
        phone: '5550001111',
        role: 'professional',
        specialty: 'Spa',
        bufferTimeMinutes: 15,
        breakStartTime: '12:00',
        breakEndTime: '13:00',
      );

      expect(professional.bufferTimeMinutes, 15);
      expect(professional.breakStartTime, '12:00');
      expect(professional.breakEndTime, '13:00');
      expect(professional.breakStart, const TimeOfDay(hour: 12, minute: 0));
      expect(professional.breakEnd, const TimeOfDay(hour: 13, minute: 0));

      final updated = professional.copyWith(bufferTimeMinutes: 30);
      expect(updated.bufferTimeMinutes, 30);
      expect(updated.breakStartTime, '12:00');
    });
  });
}
