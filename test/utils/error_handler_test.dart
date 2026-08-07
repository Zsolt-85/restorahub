import 'package:flutter_test/flutter_test.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:restorahub/exceptions/app_exception.dart';
import 'package:restorahub/utils/error_handler.dart';

void main() {
  group('ErrorHandler', () {
    group('getDisplayMessage', () {
      test('returns message for AppException', () {
        final error = const AuthException('Custom auth error', code: 'auth-failed');
        expect(ErrorHandler.getDisplayMessage(error), 'Custom auth error');
      });

      test('returns message for BookingException', () {
        final error = const BookingException('Slot no longer available');
        expect(ErrorHandler.getDisplayMessage(error), 'Slot no longer available');
      });

      test('returns mapped message for FirebaseAuthException email-already-in-use', () {
        final error = FirebaseAuthException(
          code: 'email-already-in-use',
          message: 'The email address is already in use by another account.',
        );
        expect(ErrorHandler.getDisplayMessage(error), 'Email is already in use.');
      });

      test('returns mapped message for FirebaseAuthException wrong-password', () {
        final error = FirebaseAuthException(
          code: 'wrong-password',
          message: 'The password is invalid.',
        );
        expect(ErrorHandler.getDisplayMessage(error), 'Invalid email or password.');
      });

      test('falls back to message for unmapped FirebaseAuthException', () {
        final error = FirebaseAuthException(
          code: 'some-unknown-code',
          message: 'Something went wrong.',
        );
        expect(ErrorHandler.getDisplayMessage(error), 'Something went wrong.');
      });

      test('returns mapped message for FirebaseException permission-denied', () {
        final error = FirebaseException(
          code: 'permission-denied',
          message: 'Missing or insufficient permissions.',
          plugin: 'cloud_firestore',
        );
        expect(ErrorHandler.getDisplayMessage(error), 'You do not have permission to perform this action.');
      });

      test('returns fallback for unknown Exception', () {
        final error = Exception('something weird');
        expect(ErrorHandler.getDisplayMessage(error), 'An unexpected error occurred. Please try again.');
      });

      test('returns fallback for non-Exception object', () {
        expect(ErrorHandler.getDisplayMessage('raw string'), 'raw string');
      });
    });
  });
}
