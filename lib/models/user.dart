import 'package:flutter/material.dart';

class User {
  final int? id;
  final String name;
  final String email;
  final String phone;
  final String password;
  final String role;
  final String specialty;
  final String workStartTime;
  final String workEndTime;
  final int slotDurationMinutes;

  User({
    this.id,
    required this.name,
    required this.email,
    required this.phone,
    required this.password,
    required this.role,
    this.specialty = '',
    this.workStartTime = '09:00',
    this.workEndTime = '17:00',
    this.slotDurationMinutes = 60,
  });

  bool get isProfessional => role == 'professional';

  String get roleLabel => isProfessional ? 'Professional' : 'Customer';

  TimeOfDay get workStart => _parseTime(workStartTime);

  TimeOfDay get workEnd => _parseTime(workEndTime);

  factory User.fromMap(Map<String, dynamic> map) {
    return User(
      id: map['id'] as int?,
      name: map['name'] as String,
      email: map['email'] as String,
      phone: map['phone'] as String? ?? '',
      password: map['password'] as String,
      role: map['role'] as String,
      specialty: map['specialty'] as String? ?? '',
      workStartTime: map['workStartTime'] as String? ?? '09:00',
      workEndTime: map['workEndTime'] as String? ?? '17:00',
      slotDurationMinutes: map['slotDurationMinutes'] as int? ?? 60,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'email': email,
      'phone': phone,
      'password': password,
      'role': role,
      'specialty': specialty,
      'workStartTime': workStartTime,
      'workEndTime': workEndTime,
      'slotDurationMinutes': slotDurationMinutes,
    };
  }

  User copyWith({
    int? id,
    String? name,
    String? email,
    String? phone,
    String? password,
    String? role,
    String? specialty,
    String? workStartTime,
    String? workEndTime,
    int? slotDurationMinutes,
  }) {
    return User(
      id: id ?? this.id,
      name: name ?? this.name,
      email: email ?? this.email,
      phone: phone ?? this.phone,
      password: password ?? this.password,
      role: role ?? this.role,
      specialty: specialty ?? this.specialty,
      workStartTime: workStartTime ?? this.workStartTime,
      workEndTime: workEndTime ?? this.workEndTime,
      slotDurationMinutes: slotDurationMinutes ?? this.slotDurationMinutes,
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
