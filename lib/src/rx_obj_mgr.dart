import 'package:flutter/material.dart';

class RxObjMgr {
  static final Map<Object, dynamic> _singletonMap = {};

  static final Map<Object, dynamic Function()> _factoryMap = {};

  static T put<T>(T dependency, {String? name}) {
    final key = name ?? T;
    _singletonMap[key] = dependency;
    return dependency;
  }

  // 懒加载注入
  static void lazyPut<T>(T Function() builder, {String? name}) {
    final key = name ?? T;
    _factoryMap[key] = builder;
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
      return dependency as T;
    }

    throw "❌ [注入错误] 未找到标识为 '$key' 的实例";
  }

  // 删除实例
  static void delete<T>({String? name}) {
    final key = name ?? T;
    _singletonMap.remove(key);
    _factoryMap.remove(key);
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
    RxObjMgr.put<T>(widget.dependency, name: widget.name);
  }

  @override
  void dispose() {
    final dynamic instance = RxObjMgr.find<T>(name: widget.name);
    instance.dispose?.call();

    RxObjMgr.delete<T>(name: widget.name);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => widget.child;
}
