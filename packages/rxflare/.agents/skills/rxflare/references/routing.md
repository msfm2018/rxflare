# RxFlare routing

Source of truth:
- `rxflare_router/lib/src/rx_router_core.dart`
- `rxflare_router/lib/src/rx_route_args.dart`
- `rxflare_router/lib/src/rx_widgets_app.dart`

Import:

```dart
import 'package:rxflare_router/rxflare_router.dart';
```

or:

```dart
import 'package:rxflare/rxflare.dart';
```

## Define routes

The current `RxRoute` constructor takes a zero-argument builder:

```dart
final routes = <String, RxRoute>{
  '/': RxRoute(builder: () => const HomePage()),
  '/detail/:id': RxRoute(builder: () => const DetailPage()),
};
```

Optional fields are `path` and `guard`. The guard type is `Future<bool> Function()?`; returning `false` blocks navigation.

Do not copy the one-argument `builder: () => ...` form currently shown in the umbrella README; it does not match the source constructor.

## App shell

```dart
RxWidgetsApp(
  routes: routes,
  initialRoute: '/',
);
```

`RxWidgetsApp` wraps `WidgetsApp.router` and does not impose Material or Cupertino design. Provide your own design system and localization delegates as required by the app.

## Global router

The package exports the global `rxr` instance, which is `RxRouter.I`:

```dart
await rxr.to('/detail/123?type=hot', arguments: someObject);

final id = rxr.param('id');
final type = rxr.queryItem('type');
final args = rxr.args<MyObject>();
```

Navigation methods:
- `to<T>(path, {arguments})`
- `off<T>(path, {arguments})`
- `offAll<T>(path, {arguments})`
- `back<T>({result})`

`to`, `off`, and `offAll` return a `Future<T?>` intended to receive a result when the destination page calls `back(result: ...)`.

Current-page accessors:
- `current`
- `args<T>()`
- `query()`, `queryItem(key)`
- `params()`, `param(key)`
- `pageId()`

Tab helpers:
- `initTab(index, initialPages)`
- `initTabIfNeeded(index, initialPages)`
- `switchTab(index)`

Route definitions are registered through `RxRouter.register(routes)`; `RxWidgetsApp` currently calls registration and initialization during its build.

## Current audit caveats

- The delegate's `navigatorKey` differs from the singleton router's `navigatorKey`.
- Delegate subscriptions do not currently cover active-tab changes or tab stacks created after delegate construction.
- `off` / `offAll` remove argument entries for replaced pages but do not complete pending result futures for those removed page IDs.
- `currentConfiguration` currently returns the route name and does not reconstruct path/query parameters.
- `RxWidgetsApp.build` mutates global router state; avoid describing registration as a pure build operation.
- Route matching is based on path segment count and literal / `:parameter` segments. Query parameters are parsed separately by `Uri`.

Treat these as implementation findings pending regression tests and fixes.
