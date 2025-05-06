import 'package:flutter/foundation.dart';

class RxDebug {
  static bool isEnabled = false;

  static void log(String message) {
    if (kDebugMode && isEnabled) {
      final now = DateTime.now().toIso8601String();
      debugPrint("[Rx] $message:::$now");
    }
  }
}
