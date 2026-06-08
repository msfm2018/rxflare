import 'dart:async';
import 'package:flutter/material.dart';

import '../core/rx_state.dart';

/// =======================================================
/// RxFuture
/// =======================================================
///
/// Support:
///
///  Automatic dependency linkage
///  CancelToken
///  debounce
///  throttle
///  retry
///  polling
///  cache
///  stale-while-revalidate
///  background refresh
///  force refresh
///  soft error
///  request dedupe
///  keep previous data
///  concurrent control
///  global error handler
///
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

  ///How long is the data considered as fresh?
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
        data as T,
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
        data as T,
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
