import 'package:flutter/material.dart';

/// RxObjMgr 是一个全局依赖注入管理器
///
/// 提供单例注入、懒加载和按类型或名称查找实例的功能。
/// 可以用于全局管理对象、服务或控制器。
///
/// 示例：
/// ```dart
/// // 注册单例
/// final controller = MyController();
/// RxObjMgr.put(controller);
///
/// // 懒加载
/// RxObjMgr.lazyPut(() => MyController());
///
/// // 查找实例
/// final c = RxObjMgr.find<MyController>();
///
/// // 删除实例
/// RxObjMgr.delete<MyController>();
/// ```
class RxObjMgr {
  /// 单例对象池
  static final Map<Object, dynamic> _singletonMap = {};

  /// 工厂方法池（懒加载）
  static final Map<Object, dynamic Function()> _factoryMap = {};

  /// 注册单例对象
  ///
  /// [dependency] 要注册的对象
  /// [name] 可选名称，用于区分同类型对象
  static T put<T>(T dependency, {String? name}) {
    final key = name ?? T;
    _singletonMap[key] = dependency;
    return dependency;
  }

  /// 懒加载注入
  ///
  /// [builder] 工厂函数
  /// [name] 可选名称，用于区分同类型对象
  static void lazyPut<T>(T Function() builder, {String? name}) {
    final key = name ?? T;
    _factoryMap[key] = builder;
  }

  /// 查找实例
  ///
  /// 如果未注册单例，则尝试从懒加载工厂创建
  /// [name] 可选名称
  static T find<T>({String? name}) {
    final key = name ?? T;

    // 从单例池找
    if (_singletonMap.containsKey(key)) {
      return _singletonMap[key] as T;
    }

    // 从懒加载工厂找
    if (_factoryMap.containsKey(key)) {
      final dependency = _factoryMap[key]!();
      _singletonMap[key] = dependency;
      _factoryMap.remove(key);
      return dependency as T;
    }
    throw "❌ [注入错误] 未找到标识为 '$key' 的实例";
  }

  static T? findOrNull<T>({String? name}) {
    final key = name ?? T;

    if (_singletonMap.containsKey(key)) {
      return _singletonMap[key] as T;
    }

    return null;
  }

  /// 删除实例
  ///
  /// 会同时删除单例和工厂缓存
  static void delete<T>({String? name}) {
    final key = name ?? T;
    _singletonMap.remove(key);
    _factoryMap.remove(key);
  }
}

/// RxParent 用于将依赖注入 Widget 树
///
/// 在 Widget 生命周期内自动注册和释放对象。
/// 常用于全局或页面级控制器注入。
///
/// 示例：
/// ```dart
/// RxParent<MyController>(
///   dependency: MyController(),
///   child: MyHomePage(),
/// );
/// ```
class RxParent<T> extends StatefulWidget {
  /// 要注入的依赖对象
  final T dependency;

  /// 可选名称，用于区分同类型对象
  final String? name;

  /// 子 Widget
  final Widget child;

  /// 构造函数
  const RxParent({super.key, required this.dependency, this.name, required this.child});

  @override
  State<RxParent<T>> createState() => _RxParentState<T>();
}

class _RxParentState<T> extends State<RxParent<T>> {
  @override
  void initState() {
    super.initState();
    // 注册依赖
    RxObjMgr.put<T>(widget.dependency, name: widget.name);
  }

  // @override
  // void dispose() {
  //   // 尝试调用 dispose 方法
  //   final dynamic instance = RxObjMgr.find<T>(name: widget.name);
  //   instance?.dispose?.call();

  //   // 删除依赖
  //   RxObjMgr.delete<T>(name: widget.name);
  //   super.dispose();
  // }

  @override
  void dispose() {
    final dynamic instance = RxObjMgr.findOrNull<T>(
      name: widget.name,
    );

    instance?.dispose?.call();
    // print("---------------->${widget.name}");
    RxObjMgr.delete<T>(
      name: widget.name,
    );

    super.dispose();
  }

  @override
  Widget build(BuildContext context) => widget.child;
}
