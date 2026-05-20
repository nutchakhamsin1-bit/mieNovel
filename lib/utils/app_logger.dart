import 'package:flutter/foundation.dart';

class AppLogger {
  static void debug(String message) {
    if (kDebugMode) {
      debugPrint('[DEBUG] $message');
    }
  }

  static void info(String message) {
    if (kDebugMode) {
      debugPrint('[INFO]  $message');
    }
  }

  static void warn(String message) {
    if (kDebugMode) {
      debugPrint('[WARN]  $message');
    }
  }

  static void error(String message, [Object? error, StackTrace? stackTrace]) {
    if (kDebugMode) {
      debugPrint('[ERROR] $message');
      if (error != null) debugPrint('        $error');
      if (stackTrace != null) debugPrint('$stackTrace');
    }
  }
}
