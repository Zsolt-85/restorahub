import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../exceptions/app_exception.dart';

class ErrorHandler {
  static String getDisplayMessage(Object error) {
    if (error is String) {
      return error;
    }

    if (error is AppException) {
      return error.message;
    }

    if (error is FirebaseAuthException) {
      return _mapFirebaseAuthException(error);
    }

    if (error is FirebaseException) {
      return _mapFirebaseException(error);
    }

    if (error is Exception) {
      return 'An unexpected error occurred. Please try again.';
    }

    return 'An unexpected error occurred. Please try again.';
  }

  static String _mapFirebaseAuthException(FirebaseAuthException e) {
    switch (e.code) {
      case 'email-already-in-use':
        return 'Email is already in use.';
      case 'invalid-email':
        return 'The email address is not valid.';
      case 'weak-password':
        return 'The password provided is too weak.';
      case 'user-not-found':
        return 'No user found with this email.';
      case 'wrong-password':
        return 'Invalid email or password.';
      case 'operation-not-allowed':
        return 'Email/password accounts are not enabled. Please enable them in the Firebase Console.';
      case 'too-many-requests':
        return 'Too many attempts. Please try again later.';
      case 'network-request-failed':
        return 'Network error. Please check your connection.';
      default:
        return e.message ?? 'Authentication failed. Please try again.';
    }
  }

  static String _mapFirebaseException(FirebaseException e) {
    switch (e.code) {
      case 'permission-denied':
        return 'You do not have permission to perform this action.';
      case 'unavailable':
        return 'Service is temporarily unavailable. Please try again.';
      default:
        return e.message ?? 'A database error occurred. Please try again.';
    }
  }

  static void showErrorSnackBar(BuildContext context, Object error) {
    final messenger = ScaffoldMessenger.of(context);
    messenger.clearSnackBars();
    messenger.showSnackBar(
      SnackBar(
        content: Text(getDisplayMessage(error)),
        backgroundColor: Theme.of(context).colorScheme.error,
      ),
    );
  }
}
