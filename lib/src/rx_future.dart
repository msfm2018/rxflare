import 'dart:async';
import 'package:flutter/material.dart';

import '../rxflare.dart';

/// =======================================================
/// RxFuture
/// =======================================================
///
/// 支持：
///
/// ✅ 自动依赖联动
/// ✅ CancelToken
/// ✅ debounce
/// ✅ throttle
/// ✅ retry
/// ✅ polling
/// ✅ cache
/// ✅ stale-while-revalidate
/// ✅ background refresh
/// ✅ force refresh
/// ✅ soft error
/// ✅ request dedupe
/// ✅ keep previous data
/// ✅ concurrent control
/// ✅ global error handler
///
/// 设计目标：
///
/// ReactQuery / SWR / Riverpod AsyncValue 风格
///
/// =======================================================

class RxFuture<T> extends RxState<AsyncSnapshot<T>> {
  // =======================================================
  // constructor
  // =======================================================

  RxFuture(
    this._loader, {
    this.debounce,
    this.throttle,
    this.maxRetries = 0,
    this.retryDelay = const Duration(seconds: 1),
    this.pollInterval,
    this.enableCache = false,
    this.cacheMaxAge = const Duration(minutes: 5),
    this.staleTime = Duration.zero,
    this.maxConcurrentRequests = 1,
    this.dependencies = const [],
    this.keepPreviousData = true,
    this.skipInitialRequest = false,
  }) : super(const AsyncSnapshot.nothing()) {
    _init();
  }



  factory RxFuture.search(
    Future<T> Function(CancelToken? token) loader, {
    List<RxState> dependencies = const [],
  }) {
    return RxFuture(
      loader,
      debounce: const Duration(milliseconds: 400),
      keepPreviousData: true,
      dependencies: dependencies,
    );
  }

  factory RxFuture.poll(
    Future<T> Function(CancelToken? token) loader, {
    Duration interval = const Duration(seconds: 5),
  }) {
    return RxFuture(
      loader,
      pollInterval: interval,
      enableCache: false,
      keepPreviousData: true,
    );
  }

  // =======================================================
  // loader
  // =======================================================

  final Future<T> Function(CancelToken? token) _loader;

  // =======================================================
  // configs
  // =======================================================

  final Duration? debounce;
  final Duration? throttle;

  final int maxRetries;
  final Duration retryDelay;

  final Duration? pollInterval;

  final bool enableCache;
  final Duration cacheMaxAge;

  /// 数据多久认为是 fresh
  final Duration staleTime;

  final int maxConcurrentRequests;

  final bool keepPreviousData;

  final bool skipInitialRequest;

  // =======================================================
  // dependencies
  // =======================================================

  final List<RxState> dependencies;

  final List<VoidCallback> _depDisposers = [];

  // =======================================================
  // request state
  // =======================================================

  int _requestId = 0;

  int _runningRequests = 0;

  bool _disposed = false;

  bool _forceRefresh = false;

  CancelToken? _cancelToken;

  // =======================================================
  // ui state
  // =======================================================

  bool _isRefreshing = false;

  bool _isRetrying = false;

  bool _isPolling = false;

  Object? _lastSoftError;

  // =======================================================
  // cache
  // =======================================================

  T? _cache;

  DateTime? _cacheTime;

  // =======================================================
  // timers
  // =======================================================

  Timer? _debounceTimer;

  Timer? _throttleTimer;

  Timer? _pollTimer;

  // =======================================================
  // global error
  // =======================================================

  static void Function(Object error, StackTrace stack)? globalOnError;

  // =======================================================
  // init
  // =======================================================

  void _init() {
    _listenDependencies();

    if (pollInterval != null) {
      _startPolling();
    }

    if (!skipInitialRequest) {
      _execute();
    }
  }

  void _listenDependencies() {
    for (final dep in dependencies) {
      final disposer = dep.listen((_) {
        refresh(force: true);
      });

      _depDisposers.add(disposer);
    }
  }

  // =======================================================
  // execute
  // =======================================================

  void _execute({
    bool polling = false,
    bool retrying = false,
  }) {
    if (_disposed) return;

    _isPolling = polling;

    _isRetrying = retrying;

    _debounceTimer?.cancel();

    if (debounce != null) {
      _debounceTimer = Timer(
        debounce!,
        _startRequest,
      );
    } else {
      _startRequest();
    }
  }

  // =======================================================
  // request
  // =======================================================

  Future<void> _startRequest() async {
    if (_disposed) return;

    // throttle
    if (throttle != null && _throttleTimer != null) {
      return;
    }

    if (throttle != null) {
      _throttleTimer = Timer(
        throttle!,
        () => _throttleTimer = null,
      );
    }

    // concurrent limit
    if (_runningRequests >= maxConcurrentRequests) {
      return;
    }

    // cache hit
    if (!_forceRefresh && _cacheValid()) {
      _restoreCache();
      return;
    }

    // cancel previous
    _cancelCurrentRequest();

    _runningRequests++;

    final currentRequestId = ++_requestId;

    final token = CancelToken();

    _cancelToken = token;

    _setLoadingState();

    try {
      final result = await _runWithRetry(token);

      if (!_isRequestValid(currentRequestId, token)) {
        return;
      }

      _onSuccess(result);
    } catch (e, s) {
      if (!_isRequestValid(currentRequestId, token)) {
        return;
      }

      _onError(e, s);
    } finally {
      _runningRequests--;

      _forceRefresh = false;

      if (_cancelToken == token) {
        _cancelToken = null;
      }
    }
  }

  // =======================================================
  // retry
  // =======================================================

  Future<T> _runWithRetry(
    CancelToken token,
  ) async {
    int attempt = 0;

    while (true) {
      try {
        return await _loader(token);
      } catch (e) {
        if (token.isCanceled) {
          rethrow;
        }

        attempt++;

        if (attempt > maxRetries) {
          rethrow;
        }

        await Future.delayed(
          retryDelay * attempt,
        );
      }
    }
  }

  // =======================================================
  // state
  // =======================================================

  void _setLoadingState() {
    if (keepPreviousData && hasData) {
      value = AsyncSnapshot.withData(
        ConnectionState.waiting,
        data!,
      );
    } else {
      value = const AsyncSnapshot.waiting();
    }
  }

  void _onSuccess(T result) {
    _lastSoftError = null;

    _isRefreshing = false;

    _isRetrying = false;

    _isPolling = false;

    if (enableCache) {
      _cache = result;
      _cacheTime = DateTime.now();
    }

    value = AsyncSnapshot.withData(
      ConnectionState.done,
      result,
    );
  }

  void _onError(
    Object error,
    StackTrace stack,
  ) {
    _lastSoftError = error;

    _isRefreshing = false;

    _isRetrying = false;

    _isPolling = false;

    globalOnError?.call(error, stack);

    // soft error
    if (hasData) {
      value = AsyncSnapshot.withData(
        ConnectionState.done,
        data!,
      );
    } else {
      value = AsyncSnapshot.withError(
        ConnectionState.done,
        error,
        stack,
      );
    }
  }

  // =======================================================
  // cache
  // =======================================================

  bool _cacheValid() {
    if (!enableCache) return false;

    if (_cache == null) return false;

    if (_cacheTime == null) return false;

    return DateTime.now().difference(_cacheTime!) < cacheMaxAge;
  }

  void _restoreCache() {
    _isRefreshing = false;

    _isRetrying = false;

    _isPolling = false;

    value = AsyncSnapshot.withData(
      ConnectionState.done,
      _cache as T,
    );

    // stale-while-revalidate
    if (_isCacheStale()) {
      refresh();
    }
  }

  bool _isCacheStale() {
    if (_cacheTime == null) return true;

    return DateTime.now().difference(_cacheTime!) > staleTime;
  }

  void clearCache() {
    _cache = null;
    _cacheTime = null;
  }

  // =======================================================
  // polling
  // =======================================================

  void _startPolling() {
    _pollTimer?.cancel();

    _pollTimer = Timer.periodic(
      pollInterval!,
      (_) {
        if (isRequesting) return;

        _isPolling = true;

        refresh(force: true);
      },
    );
  }

  // =======================================================
  // public api
  // =======================================================

  @override
  void refresh({
    bool force = false,
  }) {
    if (isRequesting && !force) {
      return;
    }

    _forceRefresh = force;

    _isRefreshing = true;

    _execute();
  }

  void retry() {
    if (isRequesting) return;

    _isRetrying = true;

    _execute(retrying: true);
  }

  void cancel() {
    _cancelCurrentRequest();
  }

  void reset() {
    cancel();

    clearCache();

    _lastSoftError = null;

    _isRefreshing = false;

    _isRetrying = false;

    _isPolling = false;

    value = const AsyncSnapshot.nothing();
  }

  // =======================================================
  // internal
  // =======================================================

  void _cancelCurrentRequest() {
    _cancelToken?.cancel();
    _cancelToken = null;
  }

  bool _isRequestValid(
    int requestId,
    CancelToken token,
  ) {
    if (_disposed) return false;

    if (token.isCanceled) return false;

    return requestId == _requestId;
  }

  // =======================================================
  // getters
  // =======================================================

  bool get hasData => value.hasData;

  bool get hasError => value.hasError;

  T? get data => value.data;

  Object? get error => value.error;

  bool get isLoading => value.connectionState == ConnectionState.waiting;

  bool get isInitialLoading => isLoading && !hasData;

  bool get isRefreshing => _isRefreshing;

  bool get isRetrying => _isRetrying;

  bool get isPolling => _isPolling;

  bool get isRequesting => _cancelToken != null;

  bool get isStale => hasData && value.connectionState == ConnectionState.waiting;

  bool get hasSoftError => _lastSoftError != null;

  Object? get lastSoftError => _lastSoftError;

  DateTime? get cacheTime => _cacheTime;

  // =======================================================
  // listener helper
  // =======================================================

  VoidCallback listenState(
    VoidCallback listener,
  ) {
    return listen((_) {
      listener();
    });
  }

  // =======================================================
  // dispose
  // =======================================================

  @override
  void dispose() {
    _disposed = true;

    _cancelCurrentRequest();

    _debounceTimer?.cancel();

    _throttleTimer?.cancel();

    _pollTimer?.cancel();

    for (final disposer in _depDisposers) {
      disposer();
    }

    _depDisposers.clear();

    super.dispose();
  }
}

// =======================================================
// CancelToken
// =======================================================

class CancelToken {
  bool isCanceled = false;

  VoidCallback? onCancel;

  void cancel() {
    if (isCanceled) return;

    isCanceled = true;

    onCancel?.call();
  }
}

// import 'package:flutter/material.dart';
// import 'dart:async';

// import '../rxflare.dart';

// /// 支持：自动依赖联动、CancelToken、防抖、节流、轮询、重试、缓存、全局错误处理
// class RxFuture<T> extends RxState<AsyncSnapshot<T>> {
//   int _requestId = 0;
//   bool _disposed = false;
//   bool _isRefreshing = false;
//   bool _isStale = false;

//   Object? _lastSoftError;
//   Object? get lastSoftError => _lastSoftError;
//   bool get hasSoftError => _lastSoftError != null;

//   bool get isStale => _isStale;

//   // ====================== 核心加载函数 ======================
//   final Future<T> Function(CancelToken? cancelToken) _loader;

//   // ====================== 策略配置 ======================
//   final Duration? debounce;
//   final Duration? throttle;
//   final int? maxRetries;
//   final Duration? retryDelay;
//   final Duration? pollInterval;
//   final Duration cacheMaxAge;
//   final bool enableCache;
//   final int? maxConcurrentRequests;

//   // ====================== 依赖联动 ======================
//   final List<RxState> dependencies;
//   final List<VoidCallback> _depSubs = []; // 这里修复了类型

//   // ====================== 取消 & 状态 ======================
//   CancelToken? _cancelToken;
//   CancelToken? get cancelToken => _cancelToken;
//   bool get isRequesting => _cancelToken != null;
//   // ====================== 缓存 ======================
//   T? _cachedData;
//   DateTime? _cacheTime;

//   // ====================== 计时器 ======================
//   Timer? _debounceTimer;
//   Timer? _throttleTimer;
//   Timer? _pollTimer;

//   // ====================== 并发控制（实例级别） ======================
//   int _currentConcurrent = 0;

//   // ====================== 全局错误处理 ======================
//   static void Function(Object error, StackTrace stack)? globalOnError;

//   // ====================== 构造函数 ======================
//   RxFuture(
//     this._loader, {
//     this.debounce,
//     this.throttle,
//     this.maxRetries,
//     this.retryDelay,
//     this.pollInterval,
//     this.cacheMaxAge = const Duration(minutes: 5),
//     this.enableCache = false,
//     this.maxConcurrentRequests,
//     this.dependencies = const [],
//   }) : super(const AsyncSnapshot.nothing()) {
//     _init();
//   }

//   // ====================== 工厂方法 ======================
//   factory RxFuture.search(Future<T> Function(CancelToken?) loader) {
//     return RxFuture(
//       loader,
//       debounce: const Duration(milliseconds: 500),
//     );
//   }

//   factory RxFuture.poll(
//     Future<T> Function(CancelToken?) loader, {
//     Duration interval = const Duration(seconds: 5),
//     Duration cacheMaxAge = const Duration(minutes: 5),
//   }) {
//     return RxFuture(
//       loader,
//       pollInterval: interval,
//       enableCache: false, //轮询不需要缓存
//       cacheMaxAge: cacheMaxAge,
//     );
//   }

//   // ====================== 初始化 ======================
//   void _init() {
//     _listenDependencies();
//     if (pollInterval != null) _startPolling();
//     _execute();
//   }

//   void _listenDependencies() {
//     for (final dep in dependencies) {
//       final cancel = dep.listen((_) => _execute());
//       _depSubs.add(cancel);
//     }
//   }

//   // ====================== 执行入口 ======================
//   void _execute() {
//     _debounceTimer?.cancel();

//     if (debounce != null) {
//       _debounceTimer = Timer(debounce!, _startRequest);
//     } else {
//       _startRequest();
//     }
//   }

//   // ====================== 真正发起请求 ======================
//   Future<void> _startRequest() async {
//     if (throttle != null && _throttleTimer != null) return;
//     if (throttle != null) {
//       _throttleTimer = Timer(throttle!, () => _throttleTimer = null);
//     }

//     if (maxConcurrentRequests != null && _currentConcurrent >= maxConcurrentRequests!) {
//       return;
//     }

//     // if (enableCache && _cacheValid()) {
//     //   value = AsyncSnapshot.withData(ConnectionState.done, _cachedData!);
//     //   return;
//     // }

//     if (enableCache && _cacheValid()) {
//       _isRefreshing = false;
//       _isStale = false;

//       value = AsyncSnapshot.withData(
//         ConnectionState.done,
//         _cachedData!,
//       );
//       return;
//     }

//     _cancelCurrentRequest();
//     _currentConcurrent++;
//     final currentId = ++_requestId;

//     _cancelToken = CancelToken();
//     _setLoadingState();

//     try {
//       final data = await _runWithRetries(_cancelToken);
//       if (!_valid(currentId)) return;
//       _onSuccess(data);
//     } catch (e, s) {
//       if (!_valid(currentId) || _cancelToken?.isCanceled == true) return;
//       _onError(e, s);
//     } finally {
//       _currentConcurrent--;
//       _cancelToken = null;
//     }
//   }

//   // ====================== 重试机制 ======================
//   Future<T> _runWithRetries(CancelToken? token) async {
//     int attempt = 0;
//     while (true) {
//       try {
//         return await _loader(token);
//       } catch (e) {
//         attempt++;
//         if (maxRetries == null || attempt >= maxRetries! || (token?.isCanceled ?? false)) {
//           rethrow;
//         }
//         await Future.delayed(
//           (retryDelay ?? const Duration(seconds: 1)) * attempt,
//         );
//       }
//     }
//   }

//   // ====================== 缓存判断 ======================
//   bool _cacheValid() {
//     if (!enableCache || _cachedData == null || _cacheTime == null) return false;
//     return DateTime.now().difference(_cacheTime!) < cacheMaxAge;
//   }

//   // ====================== 状态管理 ======================
//   void _setLoadingState() {
//     if (hasData) {
//       value = AsyncSnapshot.withData(ConnectionState.waiting, data!);
//     } else {
//       value = const AsyncSnapshot.waiting();
//     }
//   }

//   void _onSuccess(T data) {
//     _lastSoftError = null;
//     _isRefreshing = false;
//     _isStale = false;

//     if (enableCache) {
//       _cachedData = data;
//       _cacheTime = DateTime.now();
//     }

//     value = AsyncSnapshot.withData(ConnectionState.done, data);
//   }

//   void _onError(Object err, StackTrace stack) {
//     _isRefreshing = false;
//     _isStale = false;
//     _lastSoftError = err;
//     globalOnError?.call(err, stack);

//     if (hasData) {
//       value = AsyncSnapshot.withData(ConnectionState.done, data!);
//     } else {
//       value = AsyncSnapshot.withError(ConnectionState.done, err, stack);
//     }
//   }

//   bool _valid(int id) => !_disposed && id == _requestId;

//   void _cancelCurrentRequest() {
//     _cancelToken?.cancel();
//     _cancelToken = null;
//   }

//   // ====================== 轮询 ======================
//   // void _startPolling() {
//   //   _pollTimer?.cancel();
//   //   _pollTimer = Timer.periodic(pollInterval!, (_) => refresh(force: true));
//   // }

//   void _startPolling() {
//     _pollTimer?.cancel();

//     _pollTimer = Timer.periodic(pollInterval!, (_) {
//       if (isRequesting) return;

//       refresh(force: true);
//     });
//   }

//   // ====================== 公开 API ======================
//   void retry() {
//     if (_isRefreshing) return;
//     _isRefreshing = true;
//     _execute();
//   }

//   @override
//   void refresh({bool force = false}) {
//     if (_isRefreshing && !force) return;
//     _isStale = true;
//     _isRefreshing = true;
//     _execute();
//   }

//   void clearCache() {
//     _cachedData = null;
//     _cacheTime = null;
//   }

//   void cancel() => _cancelCurrentRequest();

//   void reset() {
//     cancel();
//     clearCache();
//     value = const AsyncSnapshot.nothing();
//     _lastSoftError = null;
//     _isStale = false;
//     _isRefreshing = false;
//   }

//   // ====================== Getters ======================
//   bool get isInitialLoading => isLoading && !hasData;
//   bool get isLoading => value.connectionState == ConnectionState.waiting;
//   bool get isRefreshing => _isRefreshing;
//   bool get isLoadingOrRefreshing => isLoading || isRefreshing;

//   bool get hasData => value.hasData;
//   bool get hasError => value.hasError;

//   T? get data => value.data;
//   Object? get error => value.error;

//   // ====================== 监听便捷方法 ======================
//   VoidCallback listenState(VoidCallback onUpdate) {
//     return listen((_) => onUpdate());
//   }

//   // ====================== 释放 ======================
//   @override
//   void dispose() {
//     _disposed = true;
//     _cancelCurrentRequest();
//     _debounceTimer?.cancel();
//     _throttleTimer?.cancel();
//     _pollTimer?.cancel();
//     for (final sub in _depSubs) {
//       sub(); // 执行取消函数
//     }
//     _depSubs.clear();
//     super.dispose();
//   }
// }

// // ====================== CancelToken ======================
// class CancelToken {
//   bool isCanceled = false;
//   VoidCallback? onCancel;

//   void cancel() {
//     if (isCanceled) return;
//     isCanceled = true;
//     onCancel?.call();
//   }
// }
