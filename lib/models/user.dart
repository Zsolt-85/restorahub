import 'package:flutter/material.dart';

enum Role { superAdmin, businessAdmin, staff, customer }

class User {
  final String? id;
  final String name;
  final String email;
  final String phone;
  final String role;
  final String specialty;
  final String workStartTime;
  final String workEndTime;
  final int slotDurationMinutes;
  final int bufferTimeMinutes;
  final String? breakStartTime;
  final String? breakEndTime;
  final String? businessId;

  User({
    this.id,
    required this.name,
    required this.email,
    required this.phone,
    this.businessId,
    required this.role,
    this.specialty = '',
    this.workStartTime = '09:00',
    this.workEndTime = '17:00',
    this.slotDurationMinutes = 60,
    this.bufferTimeMinutes = 0,
    this.breakStartTime,
    this.breakEndTime,
  });

  bool get isProfessional => role == 'professional';

  String get roleLabel => isProfessional ? 'Professional' : 'Customer';

  TimeOfDay get workStart => _parseTime(workStartTime);

  TimeOfDay get workEnd => _parseTime(workEndTime);

  TimeOfDay? get breakStart =>
      breakStartTime != null ? _parseTime(breakStartTime!) : null;

  TimeOfDay? get breakEnd =>
      breakEndTime != null ? _parseTime(breakEndTime!) : null;

  factory User.fromMap(Map<String, dynamic> map) {
    return User(
      id: map['id']?.toString(),
      name: map['name']?.toString() ?? '',
      email: (map['email']?.toString() ?? '').toLowerCase(),
      phone: map['phone']?.toString() ?? '',
      role: map['role']?.toString() ?? 'customer',
      businessId: map['businessId']?.toString(),
      specialty: map['specialty']?.toString() ?? '',
      workStartTime: map['workStartTime']?.toString() ?? '09:00',
      workEndTime: map['workEndTime']?.toString() ?? '17:00',
      slotDurationMinutes: map['slotDurationMinutes'] as int? ?? 60,
      bufferTimeMinutes: map['bufferTimeMinutes'] as int? ?? 0,
      breakStartTime: map['breakStartTime']?.toString(),
      breakEndTime: map['breakEndTime']?.toString(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'email': email.toLowerCase(),
      'phone': phone,
      'role': role,
      'businessId': businessId,
      'specialty': specialty,
      'workStartTime': workStartTime,
      'workEndTime': workEndTime,
      'slotDurationMinutes': slotDurationMinutes,
      'bufferTimeMinutes': bufferTimeMinutes,
      'breakStartTime': breakStartTime,
      'breakEndTime': breakEndTime,
    };
  }

  User copyWith({
    String? id,
    String? name,
    String? email,
    String? phone,
    String? role,
    String? businessId,
    String? specialty,
    String? workStartTime,
    String? workEndTime,
    int? slotDurationMinutes,
    int? bufferTimeMinutes,
    String? breakStartTime,
    String? breakEndTime,
  }) {
    return User(
      id: id ?? this.id,
      name: name ?? this.name,
      email: email ?? this.email,
      phone: phone ?? this.phone,
      role: role ?? this.role,
      businessId: businessId ?? this.businessId,
      specialty: specialty ?? this.specialty,
      workStartTime: workStartTime ?? this.workStartTime,
      workEndTime: workEndTime ?? this.workEndTime,
      slotDurationMinutes: slotDurationMinutes ?? this.slotDurationMinutes,
      bufferTimeMinutes: bufferTimeMinutes ?? this.bufferTimeMinutes,
      breakStartTime: breakStartTime ?? this.breakStartTime,
      breakEndTime: breakEndTime ?? this.breakEndTime,
    );
  }

  static TimeOfDay _parseTime(String value) {
    final parts = value.split(':');
    return TimeOfDay(
      hour: int.parse(parts[0]),
      minute: int.parse(parts[1]),
    );
  }

  static String formatTime(TimeOfDay time) {
    final hour = time.hour.toString().padLeft(2, '0');
    final minute = time.minute.toString().padLeft(2, '0');
    return '$hour:$minute';
  }
}
