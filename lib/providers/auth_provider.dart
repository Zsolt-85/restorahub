import 'package:flutter/material.dart';

import '../helpers/password_helper.dart';
import '../helpers/schedule_helper.dart';
import '../helpers/session_helper.dart';
import '../helpers/validation_helper.dart';
import '../models/user.dart';
import '../repositories/booking_repository.dart';
import '../repositories/local_booking_repository.dart';

class AuthProvider extends ChangeNotifier {
  AuthProvider({BookingRepository? repository})
      : _repository = repository ?? LocalBookingRepository.instance;

  final BookingRepository _repository;

  User? currentUser;

  Future<bool> restoreSession() async {
    final userId = await SessionHelper.getUserId();
    if (userId == null) return false;

    final user = await _repository.getUserById(userId);
    if (user == null) {
      await SessionHelper.clearUserId();
      return false;
    }

    currentUser = user;
    notifyListeners();
    return true;
  }

  Future<bool> login(String email, String password) async {
    final user = await _repository.getUserByEmail(email);
    if (user == null) return false;
    if (!PasswordHelper.verify(password, user.password)) return false;

    if (!PasswordHelper.isHashed(user.password)) {
      final upgraded = user.copyWith(
        password: PasswordHelper.hash(password),
      );
      await _repository.updateUser(upgraded);
      currentUser = upgraded;
    } else {
      currentUser = user;
    }

    await SessionHelper.saveUserId(currentUser!.id!);
    notifyListeners();
    return true;
  }

  Future<void> logout() async {
    await SessionHelper.clearUserId();
    currentUser = null;
    notifyListeners();
  }

  Future<String?> updateProfile({
    required String name,
    required String email,
    required String phone,
    String? newPassword,
    String? confirmPassword,
    String? specialty,
    TimeOfDay? workStart,
    TimeOfDay? workEnd,
    int? slotDurationMinutes,
  }) async {
    final user = currentUser;
    if (user == null) return 'User not logged in';

    final nameError = ValidationHelper.validateName(name);
    if (nameError != null) return nameError;

    final emailError = ValidationHelper.validateEmail(email);
    if (emailError != null) return emailError;

    final phoneError = ValidationHelper.validatePhone(phone);
    if (phoneError != null) return phoneError;

    final wantsPasswordChange =
        newPassword != null && newPassword.trim().isNotEmpty;

    if (wantsPasswordChange) {
      final passwordError = ValidationHelper.validatePassword(newPassword);
      if (passwordError != null) return passwordError;
      if (newPassword != confirmPassword) return 'Passwords do not match';
    }

    if (user.isProfessional) {
      if (specialty == null || specialty.trim().isEmpty) {
        return 'Profession is required';
      }
      if (workStart == null || workEnd == null || slotDurationMinutes == null) {
        return 'Working hours and slot length are required';
      }

      final scheduleError = ScheduleHelper.validateWorkSchedule(
        workStart: workStart,
        workEnd: workEnd,
        slotDurationMinutes: slotDurationMinutes,
      );
      if (scheduleError != null) return scheduleError;
    }

    final trimmedEmail = email.trim();
    if (await _repository.isEmailTaken(
      trimmedEmail,
      excludeUserId: user.id,
    )) {
      return 'Email is already in use';
    }

    final updatedUser = user.copyWith(
      name: name.trim(),
      email: trimmedEmail,
      phone: phone.trim(),
      password: wantsPasswordChange
          ? PasswordHelper.hash(newPassword.trim())
          : user.password,
      role: user.role,
      specialty: user.isProfessional ? specialty!.trim() : user.specialty,
      workStartTime: user.isProfessional
          ? User.formatTime(workStart!)
          : user.workStartTime,
      workEndTime:
          user.isProfessional ? User.formatTime(workEnd!) : user.workEndTime,
      slotDurationMinutes: user.isProfessional
          ? slotDurationMinutes!
          : user.slotDurationMinutes,
    );

    final result = await _repository.updateUser(updatedUser);
    if (result <= 0) return 'Update failed';

    await _repository.syncUserInAppointments(updatedUser);

    currentUser = updatedUser;
    await SessionHelper.saveUserId(updatedUser.id!);
    notifyListeners();
    return null;
  }

  void setCurrentUser(User user) {
    currentUser = user;
    notifyListeners();
  }
}
