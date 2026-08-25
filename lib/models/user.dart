import 'package:flutter/material.dart';

enum Role { superAdmin, businessAdmin, staff, customer }

class User {
  final String? id;
  final String name;
  final String email;
  final String phone;
  final String role;
  final String category;
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
    this.category = '',
    this.workStartTime = '09:00',
    this.workEndTime = '17:00',
    this.slotDurationMinutes = 60,
    this.bufferTimeMinutes = 0,
    this.breakStartTime,
    this.breakEndTime,
  });

  bool get isStaff => role == 'professional' || role == 'staff';

  @Deprecated('Use isStaff instead')
  bool get isProfessional => isStaff;

  String get roleLabel => isStaff ? 'Professional' : 'Customer';

  TimeOfDay get workStart => _parseTime(workStartTime);

  TimeOfDay get workEnd => _parseTime(workEndTime);

  TimeOfDay? get breakStart =>
      breakStartTime != null ? _parseTime(breakStartTime!) : null;

  TimeOfDay? get breakEnd =>
      breakEndTime != null ? _parseTime(breakEndTime!) : null;

  factory User.fromMap(Map<String, dynamic> map) {
    final categoryValue = map['category']?.toString() ?? '';
    final legacySpecialty = map['specialty']?.toString() ?? '';
    final resolvedCategory = categoryValue.isNotEmpty ? categoryValue : legacySpecialty;

    return User(
      id: map['id']?.toString(),
      name: map['name']?.toString() ?? '',
      email: (map['email']?.toString() ?? '').toLowerCase(),
      phone: map['phone']?.toString() ?? '',
      role: map['role']?.toString() ?? 'customer',
      businessId: map['businessId']?.toString(),
      category: resolvedCategory,
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
      'category': category,
      'specialty': category,
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
    String? category,
    @Deprecated('Use category instead') String? specialty,
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
      category: category ?? specialty ?? this.category,
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
