import 'dart:async';
import 'package:flutter/widgets.dart';

/// 表示路由栈中的一个页面实例。
///
/// 包含页面的基本路由信息、唯一标识符以及解析后的参数。
class RxPage {
  /// 路由名称（通常是注册时的 Key，如 '/home'）。
  final String name;

  /// 页面的唯一标识符，用于参数管理和结果回传。
  final String pageId;

  /// 路径参数（例如 `/detail/:id` 解析出的 id）。
  final Map<String, String> params;

  /// URL 查询参数（例如 `?type=1`）。
  final Map<String, String> query;

  RxPage({required this.name, required this.pageId, this.params = const {}, this.query = const {}});
}

/// 全局页面参数存储器。
///
/// 通过 [pageId] 存取页面跳转时传递的自定义对象。
class RxArgs {
  RxArgs._();

  /// 单例实例。
  static final I = RxArgs._();

  final Map<String, dynamic> _store = {};

  /// 为指定页面设置参数。
  void set(String pageId, dynamic value) {
    _store[pageId] = value;
  }

  /// 获取指定页面的参数，支持泛型转换。
  T? get<T>(String pageId) {
    return _store[pageId] as T?;
  }

  /// 页面销毁时移除对应的参数存储，防止内存泄漏。
  void remove(String pageId) {
    _store.remove(pageId);
  }
}

/// 路由结果回传处理器。
///
/// 配合 [Completer] 实现 `rxr.to()` 的异步等待功能。
class RxRes {
  static final _map = <String, Completer<dynamic>>{};

  /// 注册一个等待任务，返回 [Future]。
  static Future<T?> wait<T>(String pageId) {
    final c = Completer<T?>();
    _map[pageId] = c;
    return c.future;
  }

  /// 完成等待任务并传递返回结果。
  static void complete(String pageId, dynamic result) {
    _map.remove(pageId)?.complete(result);
  }
}

/// 路由定义信息。
///
/// 用于在路由表中描述路径映射规则。
class RxDef {
  /// 页面构建器。
  final Widget Function() builder;

  /// 路由守卫。返回 false 则拦截跳转。
  final Future<bool> Function()? guard;

  /// 注册的路径规则（支持 :id 格式）。
  /// 如果不传，则默认使用注册时的 key 作为 path
  final String? path;

  RxDef({required this.builder,  this.path, this.guard});
}


/// 路由匹配成功后的中间结果。
class RxHit {
  /// 匹配到的路由 Key。
  final String name;

  /// 解析出的路径参数。
  final Map<String, String> params;

  RxHit(this.name, this.params);
}

/// 路由路径解析工具类。
class RxHiter {

  static RxHit? match(String input, Map<String, RxDef> routes) {
  final inputUri = Uri.parse(input);
  final inputSegments = inputUri.pathSegments;

  for (final entry in routes.entries) {
    final def = entry.value;
    final pattern = Uri.parse(def.path ?? entry.key).pathSegments;  // 使用 effective path

    if (pattern.length != inputSegments.length) continue;

    final params = <String, String>{};
    bool ok = true;

    for (int i = 0; i < pattern.length; i++) {
      final p = pattern[i];
      final v = inputSegments[i];

      if (p.startsWith(':')) {
        params[p.substring(1)] = v;
      } else if (p != v) {
        ok = false;
        break;
      }
    }

    if (ok) {
      return RxHit(entry.key, params);   // 仍然返回注册时的 key
    }
  }
  return null;
}
}
