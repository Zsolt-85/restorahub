import 'dart:developer';
import 'package:flutter/foundation.dart';

class AppLogger {
  const AppLogger._();

  static bool _isReleaseMode = kReleaseMode;

  static dynamic _logFn = log;

  @visibleForTesting
  static void setReleaseModeForTest(bool value) {
    _isReleaseMode = value;
  }

  @visibleForTesting
  static void setLogFn(dynamic fn) {
    _logFn = fn;
  }

  static void info(String message, {String? tag}) {
    if (_isReleaseMode) return;
    _emit('INFO', message, tag: tag);
  }

  static void warning(String message, {String? tag}) {
    if (_isReleaseMode) return;
    _emit('WARNING', message, tag: tag);
  }

  static void error(String message, {String? tag}) {
    if (_isReleaseMode) return;
    _emit('ERROR', message, tag: tag);
  }

  static void debug(String message, {String? tag}) {
    if (_isReleaseMode) return;
    _emit('DEBUG', message, tag: tag);
  }

  static int levelFor(String level) {
    switch (level) {
      case 'ERROR':
        return 1200;
      case 'WARNING':
        return 900;
      case 'INFO':
        return 800;
      case 'DEBUG':
        return 500;
      default:
        return 0;
    }
  }

  static void _emit(String level, String message, {String? tag}) {
    _logFn(
      message,
      name: tag ?? 'App',
      level: levelFor(level),
    );
  }
}
