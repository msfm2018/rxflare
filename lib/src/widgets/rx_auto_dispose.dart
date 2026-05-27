import 'package:flutter/material.dart';

import '../async/rx_future.dart';
import '../core/base_.dart';
import '../utils/rx_event_bus.dart';

/// ====================== RxFuture 兼容扩展（关键） ======================
/// 让 RxFuture 拥有 .disposable 属性
extension RxFutureDisposable<T> on RxFuture<T> {
  Disposable get disposable => _RxFutureDisposable(this);
}

/// ====================== 链式 autoDispose 扩展 ======================

/// RxFuture 支持 .autoDispose(this)
extension AutoDisposeRxFuture<T> on RxFuture<T> {
  RxFuture<T> autoDispose(RxAutoDispose mixin) {
    mixin.autoDispose(disposable); // 这里使用 .disposable
    return this;
  }
}

/// listen() 返回的取消函数支持 .autoDispose(this)
extension AutoDisposeListener on VoidCallback {
  VoidCallback autoDispose(RxAutoDispose mixin) {
    mixin.autoDisposeListener(this);
    return this;
  }
}

/// EventToken 支持 .autoDispose(this)
extension AutoDisposeEventToken on EventToken {
  EventToken autoDispose(RxAutoDispose mixin) {
    mixin.autoDispose(_EventTokenDisposable(this));
    return this;
  }
}

/// ====================== 内部包装类 ======================

class _RxFutureDisposable<T> implements Disposable {
  final RxFuture<T> future;
  _RxFutureDisposable(this.future);

  @override
  void dispose() => future.dispose();
}

class _EventTokenDisposable implements Disposable {
  final EventToken token;
  _EventTokenDisposable(this.token);

  @override
  void dispose() => RxEventBus.offByToken(token);
}

class _VoidCallbackDisposable implements Disposable {
  final VoidCallback callback;
  _VoidCallbackDisposable(this.callback);

  @override
  void dispose() => callback();
}

/// ====================== RxAutoDispose Mixin ======================
mixin RxAutoDispose<T extends StatefulWidget> on State<T> {
  final List<Disposable> _disposables = [];

  void autoDispose(Disposable disposable) {
    _disposables.add(disposable);
  }

  /// 可选：传统方式创建 Token
  EventToken autoDisposeToken() {
    final token = EventToken();
    autoDispose(_EventTokenDisposable(token));
    return token;
  }

  void autoDisposeListener(VoidCallback cancelCallback) {
    autoDispose(_VoidCallbackDisposable(cancelCallback));
  }

  @override
  void dispose() {
    for (final disposable in _disposables.reversed) {
      disposable.dispose();
    }
    _disposables.clear();
    super.dispose();
  }
}
