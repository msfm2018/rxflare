import 'package:flutter/material.dart';

import '../async/rx_future.dart';
import '../core/base_.dart';
import '../utils/rx_event_bus.dart';

/// ====================== RxFuture Disposable Extension ======================

/// Extension to make [RxFuture] support automatic disposal.
extension RxFutureDisposable<T> on RxFuture<T> {
  Disposable get disposable => _RxFutureDisposable(this);
}

/// ====================== Auto Dispose Chain Extensions ======================

/// Provides convenient `.autoDispose()` chain methods for common RxFlare objects.
extension AutoDisposeRxFuture<T> on RxFuture<T> {
  RxFuture<T> autoDispose(RxAutoDispose mixin) {
    mixin.autoDispose(disposable); // 这里使用 .disposable
    return this;
  }
}

/// Allows listener cancel callbacks to be automatically disposed.
extension AutoDisposeListener on VoidCallback {
  VoidCallback autoDispose(RxAutoDispose mixin) {
    mixin.autoDisposeListener(this);
    return this;
  }
}

/// Allows [EventToken] to be automatically cleaned up.
extension AutoDisposeEventToken on EventToken {
  EventToken autoDispose(RxAutoDispose mixin) {
    mixin.autoDispose(_EventTokenDisposable(this));
    return this;
  }
}

/// ====================== Internal Disposable Wrappers ======================

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

/// A mixin that helps automatically dispose RxFlare resources (listeners, futures, tokens, etc.)
/// when a [State] object is disposed.
///
/// **Usage:**
/// ```dart
/// class _MyPageState extends State<MyPage> with RxAutoDispose {
///   final count = 0.obs;
///   late final RxFuture<User> userFuture;
///
///   @override
///   void initState() {
///     super.initState();
///
///     userFuture = RxFuture(() async { ... }).autoDispose(this);
///     count.listen((v) => print(v)).autoDispose(this);
///   }
/// }
/// ```
mixin RxAutoDispose<T extends StatefulWidget> on State<T> {
  final List<Disposable> _disposables = [];

  /// Register a [Disposable] to be disposed when the State is disposed.
  void autoDispose(Disposable disposable) {
    _disposables.add(disposable);
  }

  /// Create and auto-dispose an [EventToken].
  EventToken autoDisposeToken() {
    final token = EventToken();
    autoDispose(_EventTokenDisposable(token));
    return token;
  }

  /// Register a listener cancel callback to be called on dispose.
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
