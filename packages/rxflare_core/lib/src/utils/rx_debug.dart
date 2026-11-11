import 'package:flutter/foundation.dart';

/// RxDebug 日志工具
///
/// 用于在调试模式下打印 RxFlare 的调试信息。
/// 只有当 [isEnabled] 为 true 且应用处于 debug 模式时才会输出日志。
///
/// 示例：
/// ```dart
/// // 启用日志
/// RxDebug.isEnabled = true;
///
/// RxDebug.log("这是一个调试信息");
/// ```
class RxDebug {
  /// 是否启用日志
  ///
  /// 默认值为 false。在启用后，`log` 方法会输出调试信息。
  static bool isEnabled = false;

  /// 打印调试信息
  ///
  /// [message] 要打印的日志内容。
  ///
  /// 仅在 Flutter debug 模式下且 [isEnabled] 为 true 时打印。
  /// 输出格式示例：
  /// ```
  /// [Rx] 这是一个调试信息:::2026-04-07T12:34:56.789Z
  /// ```
  static void log(String message) {
    if (kDebugMode && isEnabled) {
      final now = DateTime.now().toIso8601String();
      debugPrint("[Rx] $message:::$now");
    }
  }
}
