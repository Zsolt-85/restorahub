import 'dart:developer';

import 'package:flutter_test/flutter_test.dart';
import 'package:restorahub/utils/app_logger.dart';

void main() {
  group('AppLogger', () {
    setUp(() {
      AppLogger.setReleaseModeForTest(false);
      AppLogger.setLogFn(log);
    });

    tearDown(() {
      AppLogger.setLogFn(log);
    });

    group('levelFor', () {
      test('returns 1200 for ERROR', () {
        expect(AppLogger.levelFor('ERROR'), 1200);
      });

      test('returns 900 for WARNING', () {
        expect(AppLogger.levelFor('WARNING'), 900);
      });

      test('returns 800 for INFO', () {
        expect(AppLogger.levelFor('INFO'), 800);
      });

      test('returns 500 for DEBUG', () {
        expect(AppLogger.levelFor('DEBUG'), 500);
      });

      test('returns 0 for unknown level', () {
        expect(AppLogger.levelFor('UNKNOWN'), 0);
      });
    });

    group('release mode', () {
      test('suppresses info output when release mode is active', () {
        bool called = false;
        AppLogger.setLogFn((String? message, {int? level, DateTime? time, int? sequenceNumber, int? terminalWidth, String? name, String? error, StackTrace? stackTrace}) {
          called = true;
        });

        AppLogger.setReleaseModeForTest(true);
        AppLogger.info('test', tag: 'Tag');
        expect(called, isFalse);
      });

      test('allows info output when release mode is inactive', () {
        bool called = false;
        String? capturedName;
        AppLogger.setLogFn((String? message, {int? level, DateTime? time, int? sequenceNumber, int? terminalWidth, String? name, String? error, StackTrace? stackTrace}) {
          called = true;
          capturedName = name;
        });

        AppLogger.setReleaseModeForTest(false);
        AppLogger.info('hello', tag: 'Tag');
        expect(called, isTrue);
        expect(capturedName, 'Tag');
      });
    });
  });
}
