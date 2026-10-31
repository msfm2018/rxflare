import 'package:flutter/widgets.dart';

import '../async/rx_future.dart';
import '../core/base_.dart';
import '../core/rx_state.dart';
import '../utils/rx_event_bus.dart';

/// ====================== 内部包装器 ======================

class _CallbackDisposable implements Disposable {
  final VoidCallback callback;
  _CallbackDisposable(this.callback);

  @override
  void dispose() => callback();
}

class _EventTokenDisposable implements Disposable {
  final EventToken token;
  _EventTokenDisposable(this.token);

  @override
  void dispose() => RxEventBus.offByToken(token);
}

/// ====================== 扩展方法 ======================

extension AutoDisposeRxState<T> on RxState<T> {
  /// 把当前 RxState 注册到 State 的自动销毁列表
  RxState<T> autoDispose(RxAutoDispose host) {
    host.register(this);
    return this;
  }
}

extension AutoDisposeRxFuture<T> on RxFuture<T> {
  /// 前提：RxFuture 必须实现 Disposable
  RxFuture<T> autoDispose(RxAutoDispose host) {
    host.register(this);
    return this;
  }
}

extension AutoDisposeListener on VoidCallback {
  VoidCallback autoDispose(RxAutoDispose host) {
    host.register(_CallbackDisposable(this));
    return this;
  }
}

extension AutoDisposeEventToken on EventToken {
  EventToken autoDispose(RxAutoDispose host) {
    host.register(_EventTokenDisposable(this));
    return this;
  }
}

/// 让 State 具备自动销毁 Rx 资源的能力。
///
/// 使用示例：
/// ```dart
/// class _HomePageState extends State<HomePage> with RxAutoDispose {
///   late final count = 0.obs.autoDispose(this);
///   late final userFuture = RxFuture(...).autoDispose(this);
///
///   @override
///   void initState() {
///     super.initState();
///     count.listen((v) => print(v)).autoDispose(this);
///   }
/// }
/// ```
mixin RxAutoDispose<T extends StatefulWidget> on State<T> {
  final List<Disposable> _disposables = [];
  bool _disposed = false;

  /// 注册一个需要自动销毁的对象
  void register(Disposable disposable) {
    if (_disposed) {
      disposable.dispose();
      return;
    }
    if (!_disposables.contains(disposable)) {
      _disposables.add(disposable);
    }
  }

  /// 创建一个会自动取消的 EventToken
  EventToken autoDisposeToken() {
    final token = EventToken();
    register(_EventTokenDisposable(token));
    return token;
  }

  @override
  void dispose() {
    if (_disposed) {
      super.dispose();
      return;
    }
    _disposed = true;

    // 倒序销毁更安全
    for (final d in _disposables.reversed) {
      try {
        d.dispose();
      } catch (e, s) {
        debugPrint('RxAutoDispose error: $e\n$s');
      }
    }
    _disposables.clear();

    super.dispose();
  }
}
