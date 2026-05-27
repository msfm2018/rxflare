import 'package:flutter/material.dart';

import 'base_.dart';

/// 全局依赖注入管理器
class RxObjMgr {
  static final Map<RxKey, Object> _singletonMap = {};
  static final Map<RxKey, Object Function()> _factoryMap = {};

  // ==================== 注册 ====================

  static T put<T>(T dependency, {String? name}) {
    final key = RxKey(T, name);
    _singletonMap[key] = dependency as Object;
    return dependency;
  }

  static void lazyPut<T>(T Function() builder, {String? name}) {
    final key = RxKey(T, name);
    _factoryMap[key] = builder as Object Function();
  }

  // ==================== 查找 ====================

  static T find<T>({String? name}) {
    final result = _findInternal<T>(name: name, throwIfNotFound: true);
    return result as T;
  }

  static T? findOrNull<T>({String? name}) {
    return _findInternal<T>(name: name, throwIfNotFound: false);
  }

  static T? _findInternal<T>({
    String? name,
    required bool throwIfNotFound,
  }) {
    final key = RxKey(T, name);

    // 已存在
    final existing = _singletonMap[key];
    if (existing != null) {
      return existing as T;
    }

    // 懒加载
    final factory = _factoryMap[key];
    if (factory != null) {
      final dep = factory();
      _singletonMap[key] = dep;
      _factoryMap.remove(key);
      return dep as T;
    }

    // 未找到
    if (throwIfNotFound) {
      throw "[注入错误] 未找到 '$key'";
    }

    return null;
  }

  // ==================== 删除 ====================

  static void delete<T>({String? name}) {
    final key = RxKey(T, name);

    final instance = _singletonMap[key];

    // 自动 dispose（安全）
    if (instance is Disposable) {
      instance.dispose();
    }

    _singletonMap.remove(key);
    _factoryMap.remove(key);
  }
}

/// Widget 注入容器
class RxParent<T> extends StatefulWidget {
  final T dependency;
  final String? name;
  final Widget child;

  const RxParent({
    super.key,
    required this.dependency,
    this.name,
    required this.child,
  });

  @override
  State<RxParent<T>> createState() => _RxParentState<T>();
}

class _RxParentState<T> extends State<RxParent<T>> {
  @override
  void initState() {
    super.initState();
    RxObjMgr.put<T>(widget.dependency, name: widget.name);
  }

  @override
  void dispose() {
    // 直接 delete（内部已经会 dispose）
    RxObjMgr.delete<T>(name: widget.name);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => widget.child;
}
