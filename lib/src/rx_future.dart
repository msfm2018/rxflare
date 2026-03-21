import 'package:flutter/material.dart';
import 'rx_state.dart';
import 'rx_debug.dart';

class RxFuture<T> extends RxState<AsyncSnapshot<T>> {
  int _requestId = 0;
  bool _disposed = false;
  bool _isRefreshing = false;
  Object? _lastError;
  bool _isStale = false;

  Object? get lastError => _lastError;
  bool get hasSoftError => _lastError != null;
  bool get isStale => _isStale;

  final Future<T> Function() _loader;

  RxFuture(this._loader) : super(const AsyncSnapshot.nothing()) {
    _subscribe(_loader());
  }

  void _subscribe(Future<T> future) {
    final int currentId = ++_requestId;

    // 更新状态：如果已有数据，保持数据并将状态切为 waiting (即正在刷新)
    if (value.hasData) {
      value = AsyncSnapshot.withData(ConnectionState.waiting, value.data as T);
    } else {
      value = const AsyncSnapshot.waiting();
    }

    future.then((data) {
      if (_disposed || currentId != _requestId) return;
      _lastError = null; // 🔥 清理
      _isRefreshing = false;
      _isStale = false; // ✅ 放这里！
      value = AsyncSnapshot.withData(ConnectionState.done, data);
    }).catchError((err, stack) {
      if (_disposed || currentId != _requestId) return;

      _isRefreshing = false;
      _isStale = false; // ✅ 错误也要结束 stale
      _lastError = err;

      if (value.hasData) {
        value = AsyncSnapshot.withData(ConnectionState.done, value.data as T);
      } else {
        value = AsyncSnapshot.withError(ConnectionState.done, err, stack);
      }

      RxDebug.log("❌ RxFuture 异步任务失败: $err");
    });
  }

// if (rx.hasError) {
//   Button(onPressed: rx.retry)
// }

  void retry() {
    if (_isRefreshing) return;

    _isRefreshing = true;
    _subscribe(_loader());
  }

  void refresh({bool force = false}) {
    if (_isRefreshing && !force) return;
    _isStale = true;
    _isRefreshing = true;

    // 🔥 立即触发一次状态更新
    value = value;

    _subscribe(_loader());
  }
  // ========= 增强型状态访问 =========

  // 是否正在加载（初次加载且无数据）
  bool get isInitialLoading => isLoading && !hasData;

  // 是否正在刷新（已有数据，正在获取更新）
  bool get isRefreshing => _isRefreshing;

  bool get isLoading => value.connectionState == ConnectionState.waiting;
  bool get hasData => value.hasData;
  bool get hasError => value.hasError;

  T? get data => value.data;
  Object? get error => value.error;

  @override
  void dispose() {
    _disposed = true;
    super.dispose();
  }
}
