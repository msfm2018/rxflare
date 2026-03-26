import 'package:flutter/material.dart';
import 'rx_debug.dart';

class RxGet {
  // 1. 实例池：Key 可以是 Type，也可以是 String
  static final Map<Object, dynamic> _singletonMap = {};

  // 2. 预约表 (懒加载)
  static final Map<Object, dynamic Function()> _factoryMap = {};

  // 注入实例 (支持可选的 name)
  static T put<T>(T dependency, {String? name}) {
    final key = name ?? T; // 如果有名字用名字，没名字用类型
    _singletonMap[key] = dependency;
    RxDebug.log("📥 [注入] 已存入: $key");
    return dependency;
  }

  /// 懒加载注入
  static void lazyPut<T>(T Function() builder, {String? name}) {
    final key = name ?? T;
    _factoryMap[key] = builder;
    RxDebug.log("🕒 [预约] 已登记: $key");
  }

  // 查找实例 (支持 find<T>() 或 find(name: "...") )
  static T find<T>({String? name}) {
    final key = name ?? T;

    // 先从单例池找
    if (_singletonMap.containsKey(key)) {
      return _singletonMap[key] as T;
    }

    // 再从预约表找
    if (_factoryMap.containsKey(key)) {
      final dependency = _factoryMap[key]!();
      _singletonMap[key] = dependency;
      _factoryMap.remove(key);
      RxDebug.log("🚀 [激活] 实例已创建: $key");
      return dependency as T;
    }

    throw "❌ [注入错误] 未找到标识为 '$key' 的实例";
  }

  // 删除实例
  static void delete<T>({String? name}) {
    final key = name ?? T;
    _singletonMap.remove(key);
    _factoryMap.remove(key);
    RxDebug.log("🗑️ [清理] 已移除: $key");
  }
}

class RxParent<T> extends StatefulWidget {
  final T dependency;
  final String? name; // 新增：支持按名注入
  final Widget child;

  const RxParent({super.key, required this.dependency, this.name, required this.child});

  @override
  State<RxParent<T>> createState() => _RxParentState<T>();
}

class _RxParentState<T> extends State<RxParent<T>> {
  @override
  void initState() {
    super.initState();
    RxGet.put<T>(widget.dependency, name: widget.name);
  }

  @override
  void dispose() {
    final instance = RxGet.find<T>(name: widget.name);
    if (instance is dynamic) {
      // print("【调试日志】_RxParentState dispose 调用，实例 ${widget.name ?? T} ${instance.dispose != null ? '存在 dispose 方法' : '不存在 dispose 方法'}");
      instance.dispose?.call();
    }
    RxGet.delete<T>(name: widget.name);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => widget.child;
}
