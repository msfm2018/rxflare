# Migration from RxFlare 1.x to 2.0

This guide reflects the `MIGRATION.md`, package exports, and source in this 2.0.0 archive.

## Package split

The monorepo now publishes four packages:

| Package | Responsibility |
|---|---|
| `rxflare_core` | `.rx`, `RxState`, computed, batch, untracked, effect, watch, Rx widgets, collections, DI, event bus, `RxFuture` |
| `rxflare_router` | `RxRouter`, `rxr`, `RxWidgetsApp`, route args and guards |
| `rxflare_i18n` | `RxLocale` |
| `rxflare` | Umbrella package re-exporting core, router, and i18n |

Most applications can keep a single dependency:

```yaml
dependencies:
  rxflare: ^2.0.0
```

For state management only:

```yaml
dependencies:
  rxflare_core: ^2.0.0
```

## Removed APIs and replacements

| Removed API | 2.0 replacement |
|---|---|
| `RxObjMgr` | `RxDI` |
| `RxParent` | `RxProvider` |
| `RxMaterialApp` | `RxWidgetsApp` plus the application's own Material/Cupertino/custom app shell |

`RxStack` belongs to `rxflare_core`, not the router package.

## Effects and batching

`effect` and `watch` are available in 2.0. `batch` groups multiple writes:

```dart
batch(() {
  first.value = 'Ada';
  last.value = 'Lovelace';
});
```

Since 1.8.2, Rx widget refresh can use synchronous `setState` when the scheduler phase permits it. Group multiple writes in `batch` when you want notification coalescing.

## Refresh semantics documented by this snapshot

1. A write outside `batch` notifies listeners immediately.
2. A write inside `batch` queues notifications until the outermost batch exits.
3. `effect` reruns are coalesced through a microtask.
4. `untracked` suppresses dependency collection for reads in its callback.
5. Full `value = ...` writes notify global listeners.
6. Field/index writes through the fine-grained collection APIs notify the corresponding field listeners.

## API naming

The current RxFlare source in this updated Skill uses `.rx` as the preferred universal conversion extension. `.rx` remains available as a deprecated compatibility alias. Dedicated collection extensions use `.rxList`, `.rxMap`, `.rxSet`, `.rxMapD`, and `.rxListMap`; the corresponding `.rx*` getters are deprecated aliases.

## Migration checks

- Update dependency declarations to the package(s) actually used.
- Replace `RxObjMgr` with `RxDI`.
- Replace `RxParent` with `RxProvider`.
- Replace `RxMaterialApp` with the application's own UI shell and `RxWidgetsApp` where the router is used.
- Check route builder signatures against `RxRoute` in the installed version: current source uses `Widget Function()`.
- Review listener ownership and dispose callbacks.
- Add regression tests for batch timing and field-level updates.
- Do not assume the README, migration guide, and source are fully synchronized; the source signature is authoritative for this archive.


## Reactive extension naming and migration

For new code, use `.rx` to create an `RxState<T>`:

```dart
final count = 0.rx;
final user = userModel.rx;
```

The `.rx` getter is retained as a deprecated compatibility alias. Migrate by replacing `value.rx` with `value.rx`.

Dedicated reactive collections use the matching `rx` names:

| Deprecated | Preferred | Result |
|---|---|---|
| `.rxList` | `.rxList` | `RxList<T>` |
| `.rxMap` | `.rxMap` | `RxMap<K, V>` |
| `.rxSet` | `.rxSet` | `RxSet<T>` |
| `.rxMapD` | `.rxMapD` | `RxMap<String, dynamic>` |
| `.rxListMap` | `.rxListMap` | `RxList<Map<String, dynamic>>` |

Do not confuse `value.rx` with `list.rxList`: the former creates `RxState<List<T>>`; the latter creates the dedicated `RxList<T>` collection with collection-specific operations and dependency behavior.
