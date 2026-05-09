import 'package:flutter/material.dart';
import 'rx_state.dart';
import 'rx_debug.dart';

/// RxFuture 是一个增强型异步状态管理类
///
/// 基于 `[RxState]<[AsyncSnapshot]<T>>`，用于管理异步任务的状态、刷新、重试和错误处理。
///
/// 特点：
/// - 自动追踪异步任务状态（loading、done、error）
/// - 提供 `retry()` 方法重试任务
/// - 提供 `refresh()` 方法刷新任务（可标记为 stale）
/// - 提供丰富状态访问属性：`isLoading`, `isRefreshing`, `hasData`, `hasError`, `data`, `error`
///
/// 示例：
///
/// ```dart
/// final rx = RxFuture<String>(() async {
///   await Future.delayed(Duration(seconds: 2));
///   return "Hello RxFuture";
/// });
///
/// rx.listen((snapshot) {
///   if (snapshot.hasData) print("数据: ${snapshot.data}");
///   if (snapshot.hasError) print("错误: ${snapshot.error}");
/// });
///
/// // 手动刷新
/// rx.refresh();
///
/// // 失败后重试
/// rx.retry();
/// ```
class RxFuture<T> extends RxState<AsyncSnapshot<T>> {
  /// 内部请求 ID，用于标记当前异步任务
  int _requestId = 0;

  /// 是否已被释放
  bool _disposed = false;

  /// 是否正在刷新
  bool _isRefreshing = false;

  /// 上一次错误对象
  Object? _lastError;

  /// 当前数据是否为 stale（过期）
  bool _isStale = false;

  /// 获取上一次错误
  Object? get lastError => _lastError;

  /// 是否存在软错误（错误但仍有数据）
  bool get hasSoftError => _lastError != null;

  /// 当前数据是否过期
  bool get isStale => _isStale;

  /// 异步加载函数
  final Future<T> Function() _loader;

  /// 构造函数
  ///
  /// [_loader] 异步任务函数
  RxFuture(this._loader) : super(const AsyncSnapshot.nothing()) {
    _subscribe(_loader());
  }

  /// 内部订阅异步任务
  void _subscribe(Future<T> future) {
    final int currentId = ++_requestId;

    // 更新状态
    if (value.hasData) {
      value = AsyncSnapshot.withData(ConnectionState.waiting, value.data as T);
    } else {
      value = const AsyncSnapshot.waiting();
    }

    future.then((data) {
      if (_disposed || currentId != _requestId) return;
      _lastError = null;
      _isRefreshing = false;
      _isStale = false;
      value = AsyncSnapshot.withData(ConnectionState.done, data);
    }).catchError((err, stack) {
      if (_disposed || currentId != _requestId) return;
      _isRefreshing = false;
      _isStale = false;
      _lastError = err;

      if (value.hasData) {
        value = AsyncSnapshot.withData(ConnectionState.done, value.data as T);
      } else {
        value = AsyncSnapshot.withError(ConnectionState.done, err, stack);
      }

      RxDebug.log("❌ RxFuture 异步任务失败: $err");
    });
  }

  ///listenState 的作用是：当 RxFuture 内部状态发生变化（loading → done → error）时，通知外部。
  /// ✅ 推荐写法：支持 c.userFuture.listenState(() => setState(() {}))
  void Function() listenState(void Function() onUpdate) {
    void wrapper(AsyncSnapshot<T> _) => onUpdate();
    return super.listen(wrapper);
  }

  /// 保留原始功能（接收 AsyncSnapshot）
  void Function() listenWithSnapshot(void Function(AsyncSnapshot<T>) onUpdate) {
    return super.listen(onUpdate);
  }

  /// 重试异步任务
  ///
  /// 如果当前正在刷新，则跳过
  void retry() {
    if (_isRefreshing) return;
    _isRefreshing = true;
    _subscribe(_loader());
  }

  /// 刷新异步任务
  ///
  /// [force] 是否强制刷新，即使当前正在刷新
  @override
  void refresh({bool force = false}) {
    if (_isRefreshing && !force) return;
    _isStale = true;
    _isRefreshing = true;

    // 立即触发一次状态更新
    value = value;

    _subscribe(_loader());
  }

  /// 是否正在首次加载（初次加载且无数据）
  bool get isInitialLoading => isLoading && !hasData;

  /// 是否正在刷新（已有数据，正在获取更新）
  bool get isRefreshing => _isRefreshing;

  /// 是否正在加载
  bool get isLoading => value.connectionState == ConnectionState.waiting;

  /// 是否有数据
  bool get hasData => value.hasData;

  /// 是否有错误
  bool get hasError => value.hasError;

  /// 获取数据
  T? get data => value.data;

  /// 获取错误对象
  Object? get error => value.error;

  @override

  /// 释放资源
  void dispose() {
    _disposed = true;
    super.dispose();
  }
}
