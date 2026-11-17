# Computed values, effects, watch, batch, and dependency tracking

Source of truth:
- `rxflare_core/lib/src/core/rx_computed.dart`
- `rxflare_core/lib/src/core/rx_effect.dart`
- `rxflare_core/lib/src/core/rx_stack.dart`
- `rxflare_core/lib/src/core/rx_batch.dart`
- `rxflare_core/test/rx_effect/rx_effect_test.dart`
- `rxflare_core/test/rx_computed/rx_computed_field_test.dart`

## computed

`computed<T>(T Function() fn)` returns `RxComputed<T>`:

```dart
final first = 10.rx;
final second = 20.rx;
final sum = computed(() => first.value + second.value);

print(sum.value);
first.value = 15;
print(sum.value);
```

Dependencies are automatically collected from `RxState` and field-level collection reads. The computed value is read-only; update its sources rather than assigning `sum.value`.

Dispose it with `sum.dispose()`.

## effect

`effect` executes immediately, tracks dependencies read during the callback, and returns a stop function:

```dart
final stop = effect(() {
  debugPrint('count=${count.value}');
});

// Later:
stop();
```

The current implementation coalesces dependency notifications into a microtask using `scheduleMicrotask`. This differs from the synchronous listener notification used by ordinary `RxState` writes. Tests in the repository await a zero-duration Future before asserting effect reruns.

Avoid writing to a dependency from its own effect unless the feedback behavior is intentional and bounded. The current `_running` guard prevents synchronous re-entry, but a write can schedule a later microtask rerun.

## watch

```dart
final stop = watch<int>(
  () => count.value,
  (value) => debugPrint('count=$value'),
);
```

`watch` is implemented on top of `effect`. The first source evaluation occurs immediately. The callback is invoked immediately by default. Set `immediate: false` to suppress only the first callback; subsequent changes still invoke it.

The callback receives the evaluated source value. For multiple sources, return a record or another aggregate value from the source function.

## batch

```dart
batch(() {
  a.value = 1;
  b.value = 2;
});
```

Nested batches are supported. Notifications flush when the outermost batch exits, including when the callback throws (the flush happens in `finally`). Field notifications are flushed before global notifications. A state may receive both kinds if both were queued.

`batch` batches notifications; it does not make writes transactional and does not roll back values if the callback throws.

## untracked

```dart
final stop = effect(() {
  final trackedName = name.value;
  final diagnosticId = untracked(() => id.value);
  debugPrint('$trackedName ($diagnosticId)');
});
```

Reads inside `untracked` do not register dependencies in the active RxStack context.

## Dependency model

`RxStack` holds a stack of `RxContext` instances. A context records:
- state-level dependencies in `states`
- field-level dependencies in `fields`, grouped by `RxState`

`Rx` widgets, `RxComputed`, and `effect` create contexts and reconcile old dependencies against newly collected dependencies.

## Current audit note

`_RxEffect._run()` calls `_updateDeps(ctx)` only after `fn()` returns normally. If the callback throws, the previous dependency set remains installed. Before changing this, decide and test the intended exception policy (retain previous dependencies, reconcile partial dependencies, or stop the effect). Do not promise a different behavior in generated documentation.
