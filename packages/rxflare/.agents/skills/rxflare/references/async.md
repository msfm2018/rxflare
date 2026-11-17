# RxFuture and asynchronous state

Source of truth:
- `rxflare_core/lib/src/async/rx_future.dart`
- `rxflare_core/test/` (inspect focused RxFuture tests in the current checkout)

## Create an RxFuture

`RxFuture<T>` extends `RxState<AsyncSnapshot<T>>`. Its loader receives a nullable `CancelToken`:

```dart
final userRequest = RxFuture<User>(
  (token) => api.fetchUser(token: token),
  keepPreviousData: true,
  maxRetries: 2,
);
```

The constructor starts the first request by default. Set `skipInitialRequest: true` when the request should wait for an explicit `refresh()`.

## Built-in factories

```dart
final search = RxFuture<User>(
  (token) => api.searchUser(query.value, token: token),
  debounce: const Duration(milliseconds: 400),
  dependencies: [query],
);

final polling = RxFuture<Status>(
  (token) => api.fetchStatus(token: token),
  pollInterval: const Duration(seconds: 10),
);
```

The source also provides `RxFuture.search(...)` (400 ms debounce, keeps previous data) and `RxFuture.poll(...)` (polling factory; default interval 5 seconds). The search factory accepts a list of `RxState` dependencies; listeners are attached during initialization and dependency notifications request a forced refresh. Note that `listen()` emits its current value immediately, so dependency wiring itself can trigger a refresh during construction; inspect request counts if this matters.

## Main configuration

The constructor supports:

- `debounce`, `throttle`
- `maxRetries`, `retryDelay`
- `pollInterval`
- `enableCache`, `cacheMaxAge`, `staleTime`
- `maxConcurrentRequests`
- `dependencies`
- `keepPreviousData`
- `skipInitialRequest`

Read the current constructor signature before copying a configuration because not every advertised feature implies every combination is supported.

## Read request state

```dart
Rx(() {
  if (userRequest.isInitialLoading) {
    return const CircularProgressIndicator();
  }

  if (userRequest.hasError && !userRequest.hasData) {
    return Text('Error: ${userRequest.error}');
  }

  final user = userRequest.data;
  if (user == null) return const SizedBox.shrink();

  return Text(user.name);
});
```

Public state includes `hasData`, `hasError`, `data`, `error`, `isLoading`, `isInitialLoading`, `isRefreshing`, `isRetrying`, `isPolling`, `isRequesting`, `isStale`, `hasSoftError`, `lastSoftError`, and `cacheTime`.

## Control methods

- `refresh({force = false})`
- `retry()`
- `cancel()`
- `reset()`
- `clearCache()`
- `dispose()`

A loader error is represented in the `AsyncSnapshot`; it is not rethrown from the request execution path. `globalOnError` is an optional static error callback. If previous data exists, an error can be retained as a soft error while the snapshot continues to expose the previous data.

`CancelToken` exposes `isCanceled` and `cancel()`. A loader must cooperate with the token to stop underlying I/O; marking a token canceled does not forcibly terminate an arbitrary Future.

## Lifecycle

`RxFuture` implements `Disposable`. Dispose it when its owner is finished; disposal cancels the active token, debounce/throttle/poll timers, and dependency listeners, then clears cache/error state. It can be registered with `RxAutoDispose`.

## Important implementation cautions

- The request limit is controlled by `maxConcurrentRequests`; the default is 1.
- With the default `maxConcurrentRequests: 1`, a forced refresh requested while a request is still running can hit the concurrency-limit early return before the old request is canceled. Do not assume `refresh(force: true)` always preempts an in-flight request; add a focused test before relying on that behavior.
- A polling timer skips a tick while a request is active.
- Cache behavior depends on `enableCache`, `cacheMaxAge`, and `staleTime`; inspect source and tests before relying on stale-while-revalidate timing.
- Debounce and throttle use timers. In tests, use fake async/time control where appropriate rather than real sleeps.
