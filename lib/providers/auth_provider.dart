import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart' as fb;

import '../helpers/schedule_helper.dart';
import '../helpers/validation_helper.dart';
import '../models/user.dart';
import '../repositories/user_repository.dart';
import '../repositories/firestore_user_repository.dart';

enum LoginResult {
  success,
  needsProfile,
  invalidCredentials,
}

class AuthProvider extends ChangeNotifier {
  AuthProvider({UserRepository? userRepository})
      : _userRepository = userRepository ?? FirestoreUserRepository.instance;

  final UserRepository _userRepository;

  User? currentUser;

  bool get isAuthenticated {
    try {
      return _auth.currentUser != null;
    } on Exception {
      return false;
    }
  }

  bool get isProfileComplete => currentUser != null;

  fb.FirebaseAuth get _auth => fb.FirebaseAuth.instance;

  Future<LoginResult> login(String email, String password) async {
    try {
      final cred = await _auth.signInWithEmailAndPassword(
        email: email.trim().toLowerCase(),
        password: password,
      );

      final user = await _userRepository.getUserById(cred.user!.uid);
      if (user == null) {
        return LoginResult.needsProfile;
      }

      currentUser = user;
      notifyListeners();

      return LoginResult.success;
    } catch (e, stack) {
      debugPrint('Login error: $e\n$stack');
      return LoginResult.invalidCredentials;
    }
  }

  Future<bool> createProfile({
    required String name,
    required String phone,
    required String role,
    required String specialty,
  }) async {
    try {
      final fbUser = _auth.currentUser;
      if (fbUser == null) return false;

      final newUser = User(
        id: fbUser.uid,
        name: name.trim(),
        email: fbUser.email!.toLowerCase(),
        phone: phone.trim(),
        role: role,
        specialty: role == 'professional' ? specialty.trim() : '',
      );

      final insertResult = await _userRepository.insertUser(newUser);
      if (insertResult <= 0) return false;

      currentUser = newUser;
      notifyListeners();
      return true;
    } catch (e, stack) {
      debugPrint('Create profile error: $e\n$stack');
      return false;
    }
  }

  Future<String?> register({
    required String email,
    required String password,
    required String role,
    required String name,
    required String phone,
    required String specialty,
  }) async {
    try {
      await _auth.signOut();
      currentUser = null;

      final normalizedEmail = email.trim().toLowerCase();

      final cred = await _auth.createUserWithEmailAndPassword(
        email: normalizedEmail,
        password: password,
      );

      final newUser = User(
        id: cred.user!.uid,
        name: name.trim(),
        email: normalizedEmail,
        phone: phone.trim(),
        role: role,
        specialty: specialty,
      );

      try {
        final insertResult = await _userRepository.insertUser(newUser);
        if (insertResult <= 0) {
          await cred.user?.delete();
          return 'Failed to save user profile';
        }
      } catch (e) {
        await cred.user?.delete();
        rethrow;
      }

      currentUser = newUser;
      notifyListeners();

      return null;
    } on fb.FirebaseAuthException catch (e) {
      debugPrint('Registration FirebaseAuthException: ${e.code} - ${e.message}');
      if (e.code == 'email-already-in-use') {
        return 'Email is already in use';
      } else if (e.code == 'weak-password') {
        return 'The password provided is too weak';
      } else if (e.code == 'invalid-email') {
        return 'The email address is not valid';
      } else if (e.code == 'operation-not-allowed') {
        return 'Email/password accounts are not enabled. Please enable them in the Firebase Console (Authentication -> Sign-in method).';
      }
      return e.message ?? 'Registration failed';
    } catch (e, stack) {
      debugPrint('Registration error: $e\n$stack');
      return e.toString();
    }
  }

  Future<void> logout() async {
    await _auth.signOut();

    currentUser = null;
    notifyListeners();
  }

  Future<bool> restoreSession() async {
    try {
      final fbUser = _auth.currentUser;
      if (fbUser == null) return false;

      final user = await _userRepository.getUserById(fbUser.uid);
      if (user == null) return false;

      currentUser = user;
      notifyListeners();
      return true;
    } catch (_) {
      return false;
    }
  }

  Future<String?> sendPasswordResetEmail(String email) async {
    final emailError = ValidationHelper.validateEmail(email);
    if (emailError != null) return emailError;

    try {
      await _auth.sendPasswordResetEmail(email: email.trim().toLowerCase());
      return null;
    } on fb.FirebaseAuthException catch (e) {
      return e.message ?? 'Failed to send reset email';
    } catch (_) {
      return 'Failed to send reset email';
    }
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
    int? bufferTimeMinutes,
    String? breakStartTime,
    String? breakEndTime,
  }) async {
    final user = currentUser;
    if (user == null) return 'User not logged in';

    final fbUser = _auth.currentUser;
    if (fbUser == null) return 'User not logged in';

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

    final trimmedEmail = email.trim().toLowerCase();

    if (await _userRepository.isEmailTaken(
      trimmedEmail,
      excludeUserId: user.id,
    )) {
      return 'Email is already in use';
    }

    if (wantsPasswordChange) {
      try {
        await fbUser.updatePassword(newPassword.trim());
      } on fb.FirebaseAuthException catch (e) {
        if (e.code == 'requires-recent-login') {
          return 'Please sign out and sign in again before changing your password';
        }
        return e.message ?? 'Failed to update password';
      }
    }

    if (trimmedEmail != user.email) {
      try {
        await fbUser.verifyBeforeUpdateEmail(trimmedEmail);
      } on fb.FirebaseAuthException catch (e) {
        return e.message ?? 'Failed to update email';
      }
    }

    final updatedUser = user.copyWith(
      name: name.trim(),
      email: trimmedEmail,
      phone: phone.trim(),
      role: user.role,
      specialty: user.isProfessional ? specialty!.trim() : user.specialty,
      workStartTime: user.isProfessional
          ? User.formatTime(workStart!)
          : user.workStartTime,
      workEndTime:
          user.isProfessional ? User.formatTime(workEnd!) : user.workEndTime,
      slotDurationMinutes:
          user.isProfessional ? slotDurationMinutes! : user.slotDurationMinutes,
      bufferTimeMinutes:
          user.isProfessional ? bufferTimeMinutes! : user.bufferTimeMinutes,
      breakStartTime: breakStartTime,
      breakEndTime: breakEndTime,
    );

    final result = await _userRepository.updateUser(updatedUser);
    if (result <= 0) return 'Update failed';

    await _userRepository.syncUserInAppointments(updatedUser);

    currentUser = updatedUser;
    notifyListeners();

    return null;
  }
}
