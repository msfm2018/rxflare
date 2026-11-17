# State management and widgets

Source of truth:
- `rxflare_core/lib/src/core/rx_state.dart`
- `rxflare_core/lib/src/core/rx_core.dart`
- `rxflare_core/lib/src/widgets/rx.dart`
- `rxflare_core/lib/src/widgets/rx_builder.dart`
- `rxflare_core/lib/src/widgets/rx_auto_dispose.dart`

## Create reactive state

The primary extension in `rx_core.dart` is `.rx`. The old `.obs` getter remains as a deprecated compatibility alias:

```dart
final count = 0.rx;
final title = 'Hello'.rx;
final user = <String, dynamic>{'name': 'Ada'}.rx;

// Legacy only: still compiles, but emits a deprecation warning.
final oldCount = 0.rx;
```

Equivalent explicit construction:

```dart
final count = RxState<int>(0);
```

Read and write with `.value`:

```dart
final oldValue = count.value;
count.value = oldValue + 1;
```

`RxState.value` registers a state-level dependency when read inside an active Rx tracking context. Assigning a different value notifies global listeners. Equality is checked by `deepEquals`; the current implementation uses Flutter `mapEquals` / `listEquals` for Map/List and `==` otherwise.

`RxState` also exposes `listen`, `bind`, `listenWithId`, `listenWhere`, `listenByKey`, `refresh`, `updateField`, and `dispose`. Listener methods that return a callback return a cancellation function. Do not forget to cancel it when its owner ends.

## Reactive widgets

Use `Rx` for automatic dependency tracking:

```dart
Rx(() => Text('Count: ${count.value}'));
```

Only dependencies read while the builder executes are collected. The `Rx` widget has a manual dependency mode:

```dart
Rx.custom(
  deps: [count],
  builder: () => Text('Count: ${count.value}'),
);
```

In manual mode automatic dependency tracking is disabled; the supplied state list is used for state-level listening.

Use `RxBuilder` when a `BuildContext` is needed:

```dart
RxBuilder(
  builder: (context) => Text('Count: ${count.value}'),
);
```

`Obx` is an alias-style widget extending `Rx` and uses the same automatic tracking model.

## Boolean helper

```dart
final expanded = false.rx;
expanded.toggle();
```

`toggle()` returns the resulting bool.

## Map/list state helpers

A normal List wrapped with `.rx` is still an `RxState<List<T>>`:

```dart
final names = <String>[].rx;
names.add('Ada');
names.remove('Ada');
```

The extension methods mutate the underlying List and call `refresh()`. Prefer the dedicated `RxList` when index-level dependencies are required.

For Map-like state, use `getItem(key)` to register a field dependency and `updateField(key, value)` to update a Map key or List index where supported:

```dart
final profile = <String, dynamic>{
  'name': 'Ada',
  'age': 36,
}.rx;

Rx(() => Text('${profile.getItem('name')}'));
profile.updateField('name', 'Grace');
```

The current `updateField` Map branch updates only keys that already exist. Do not document it as an insert-new-key API.

## Computed values

```dart
final price = 99.rx;
final quantity = 2.rx;
final total = computed(() => price.value * quantity.value);

Rx(() => Text('${total.value}'));
```

`computed` returns `RxComputed<T>`, which is read-only through its `value` setter. Dispose a computed value when its owner no longer needs it:

```dart
total.dispose();
```

See `effect-watch.md` for dependency and scheduling details. Note that the current constructor computes the initial expression twice; this is an audit finding, not desired behavior.

## Group writes and untracked reads

```dart
batch(() {
  firstName.value = 'Ada';
  lastName.value = 'Lovelace';
});
```

`batch` defers global and field notifications until the outermost batch completes and deduplicates queued state/field notifications.

```dart
final debugId = untracked(() => id.value);
```

`untracked` suppresses dependency registration for reads made within the callback.

## Auto disposal

`RxAutoDispose` is a mixin for a `State<T>` and can register `Disposable` objects, listener cancellation callbacks, and event tokens:

```dart
class _PageState extends State<Page> with RxAutoDispose {
  late final count = 0.rx.autoDispose(this);

  @override
  Widget build(BuildContext context) {
    return Rx(() => Text('${count.value}'));
  }
}
```

`RxState`, `RxFuture`, and other `Disposable` implementations can be registered. A listener cancellation `VoidCallback` can also use `.autoDispose(this)`.

## Import choices

```dart
import 'package:rxflare_core/rxflare_core.dart';
```

or use the umbrella:

```dart
import 'package:rxflare/rxflare.dart';
```
