# Dependency injection and lifecycle

Source of truth:
- `rxflare_core/lib/src/di/rx_di.dart`
- `rxflare_core/lib/src/di/rx_provider.dart`
- `rxflare_core/lib/src/core/base_.dart`
- `rxflare_core/lib/src/widgets/rx_auto_dispose.dart`

Import:

```dart
import 'package:rxflare_core/rxflare_core.dart';
```

## Register and find a singleton

```dart
class UserController {
  final count = 0.rx;
}

RxDI.put<UserController>(UserController());

final controller = RxDI.find<UserController>();
```

The generic type used for registration and lookup forms the key. An optional `name` disambiguates multiple registrations:

```dart
RxDI.put<ApiClient>(ApiClient(), name: 'primary');
final api = RxDI.find<ApiClient>(name: 'primary');
```

## Lazy registration

```dart
RxDI.lazyPut<AnalyticsService>(
  () => AnalyticsService(),
);

final analytics = RxDI.find<AnalyticsService>();
```

The factory is invoked on the first successful lookup and the resulting instance is stored as a singleton.

## Optional lookup and deletion

```dart
final maybeService = RxDI.findOrNull<AnalyticsService>();

RxDI.delete<AnalyticsService>();
```

When the stored instance implements `Disposable`, `delete` calls `dispose()` before removing it.

## RxProvider

`RxProvider<T>` registers its dependency in `initState` and deletes it in `dispose`:

```dart
RxProvider<UserController>(
  dependency: UserController(),
  child: const UserPage(),
);
```

This provider uses the global `RxDI` container; it is not a separate inherited lookup scope.

## Disposable and RxAutoDispose

`Disposable` defines `void dispose()`.

A `State<T>` can use the `RxAutoDispose` mixin to register disposables and listener cancellation callbacks:

```dart
class _ScreenState extends State<Screen> with RxAutoDispose {
  late final user = UserController().rx.autoDispose(this);

  @override
  Widget build(BuildContext context) => const SizedBox();
}
```

The mixin disposes registered items in reverse registration order. It catches and logs disposal exceptions.

For a listener:

```dart
late final cancel = user.listen((value) {
  // React to value.
}).autoDispose(this);
```

Do not register the same resource with multiple owners unless its disposal semantics are intentionally shared.

## Current audit caveat

`RxDI.put` overwrites an existing registration without disposing the previous instance, and `RxProvider` uses the global container. If multiple providers register the same type/name, one provider's disposal can remove a registration another widget expected to own. Treat provider nesting/ownership as a global-container concern until scoped DI is implemented.
