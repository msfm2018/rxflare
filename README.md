# rxflare

A lightweight reactive state management library for Flutter, built for high-performance UI updates with automatic dependency tracking and field-level precision.

[![Pub Version](https://img.shields.io/pub/v/rxflare.svg)](https://pub.dev/packages/rxflare)
[![License](https://img.shields.io/github/license/msfm2018/rxflare)](LICENSE)
[![Flutter](https://img.shields.io/badge/Flutter-3.0+-1EB7FF?logo=flutter&logoColor=white)]()
[![Platform](https://img.shields.io/badge/Platform-Android%20%7C%20iOS%20%7C%20Web%20%7C%20Desktop-4CAF50)]()

rxflare helps Flutter apps build reactive state with less boilerplate and more precise UI updates.

Instead of rebuilding the whole screen when one field changes, rxflare tracks dependencies and updates only the relevant widget subtree. That means:

- smaller UI rebuild scope
- less unnecessary rendering
- cleaner state logic
- better performance for forms, lists, and complex screens

## Why rxflare?

If you are tired of managing large state objects and watching whole screens redraw for a small field update, rxflare is designed for you.

It gives you:

- automatic dependency tracking
- reactive primitive values with `.obs`
- computed values
- field-level updates for Map and List
- lightweight DI and provider support
- routing support with `rxr`
- async state helpers like `RxFuture`
- event bus for decoupled communication
- paginated reactive lists for very large datasets with `RxPagedList`
## Performance

rxflare is designed for high-frequency state updates with minimal overhead.
Below are independent micro-benchmarks comparing common Flutter state solutions
on the same machine (Windows, release mode).

### 1. Pure write (no listeners)

1,000,000 writes of a simple `int` counter.

| Library              | Avg (µs / write) | Notes        |
|----------------------|------------------|--------------|
| **RxFlare (RxState)**| **0.0030**       | Fastest      |
| ChangeNotifier       | 0.0048           |              |
| ValueNotifier        | 0.0055           |              |
| Bloc Cubit           | 0.0073           |              |
| GetX (RxInt)         | 0.0082           |              |
| Signals              | 0.0111           |              |
| MobX                 | 0.0993           |              |
| Riverpod (Notifier)  | 0.7664           |              |

### 2. Write with listeners

1,000,000 writes, with 0 / 1 / 10 active listeners.

| Library          | 0 listeners | 1 listener | 10 listeners |
|------------------|-------------|------------|--------------|
| **RxFlare**      | **0.0024**  | **0.0063** | 0.0291       |
| ChangeNotifier   | 0.0051      | 0.0068     | **0.0268**   |
| ValueNotifier    | 0.0064      | 0.0090     | 0.0279       |
| GetX             | 0.0099      | 0.0158     | 0.0819       |
| Bloc Cubit       | 0.0075      | 0.0423     | 0.4138       |
| Signals          | 0.0132      | 0.0570     | 0.2943       |
| MobX             | 0.1067      | 0.1989     | 0.6801       |
| Riverpod         | 0.8277      | 0.8283     | 1.0515       |

*Unit: µs / write (lower is better)*

### 3. Real UI rebuild (batched updates)

20,000 state updates that trigger actual Widget rebuilds.
No per-frame wait (avoids being locked to 16.7 ms vsync).

| Library              | 1 Widget (µs) | 10 Widgets (µs) |
|----------------------|---------------|-----------------|
| Signals (Watch)      | **1.771**     | 2.452           |
| ValueNotifier        | 2.411         | 2.493           |
| MobX (Observer)      | 2.469         | **2.446**       |
| ChangeNotifier       | 2.488         | 2.497           |
| GetX (Obx)           | 2.490         | 2.499           |
| **RxFlare (Rx)**     | 2.598         | 2.512           |
| Bloc Cubit           | 2.502         | 4.204           |
| Riverpod             | 3.321         | 3.384           |

### Summary

| Scenario                        | Top performers                          |
|---------------------------------|-----------------------------------------|
| Pure write                      | **RxFlare**, ChangeNotifier, ValueNotifier |
| Write + listeners               | **RxFlare**, ChangeNotifier, ValueNotifier |
| Real UI rebuild                 | Signals, ValueNotifier, MobX, **RxFlare**  |

### Notes

These are micro-benchmarks focused on update and notification overhead.
Real application performance also depends on widget tree depth, build cost, and usage patterns.

Benchmark source is available in the repository / bench.
## Core features

### Reactive state

```dart
final count = 0.obs;

Rx(() => Text('count: ${count.value}'));
```

### Precise field-level updates

```dart
final user = {
  'name': 'Tom',
  'age': 25,
}.obs;

Rx(() => Text('姓名: ${user.getItem('name')}'));

user.updateField('name', 'Jerry');
```

Only the affected UI updates, without forcing unrelated widgets to rebuild.

### Computed values

```dart
final price = 99.obs;
final quantity = 2.obs;

final total = computed(() => price.value * quantity.value);

Rx(() => Text('price: ${total.value}'));
```
### Large paginated lists

`RxList` keeps every item in memory, which is not suitable for datasets with
hundreds of thousands (or millions) of rows. `RxPagedList` loads data page by
page from your backend or database, caches only recent pages, and rebuilds
only the rows that actually changed.

```dart
final users = RxPagedList<User>(
  pageSize: 50,
  maxCachedPages: 20,
  loader: (page, size) async {
    final r = await api.fetchUsers(page: page, size: size);
    return PageResult(r.items, totalCount: r.total);
  },
);

// The outer Rx depends only on the total count.
Rx(() => ListView.builder(
  itemCount: users.length,
  itemExtent: 64,
  // Each row has its own Rx and depends only on its own index.
  itemBuilder: (_, i) => Rx(() {
    if (users.statusAt(i) == RxPageStatus.error) {
      return TextButton(
        onPressed: () => users.retryPage(i ~/ users.pageSize),
        child: const Text('Retry'),
      );
    }
    final user = users[i];
    return user == null ? const SkeletonTile() : UserTile(user);
  }),
));

// Update one cached item: only that row rebuilds.
users.updateAt(3, updatedUser);

// Clear the cache and reload (pull-to-refresh, filter changed, ...).
await users.invalidate();
```

**Features**

- Lazy page loading with configurable `pageSize`, `prefetch` and `maxConcurrent`.
- LRU page cache (`maxCachedPages`). Pages currently observed by an `Rx` are never evicted.
- Index-level reactivity: when a page arrives or `updateAt()` is called, only the rows watching that index rebuild.
- Loading and error states (`statusAt`, `errorAt`) with manual `retryPage`.
- Duplicate request prevention, and stale responses are discarded after `invalidate()`.
- Known-total mode (`PageResult(items, totalCount: n)`) and infinite-scroll mode (omit `totalCount`).

**Notes**

- Read `list[i]` inside each row's own `Rx`, not in the outer one, otherwise
  every loaded page rebuilds the whole list.
- Set `maxCachedPages` larger than the number of visible pages plus `prefetch`.
- `updateAt()` only changes the local cache. Write to your backend yourself.
- Inserting or removing items shifts all later page boundaries; call
  `invalidate()` instead of patching locally.
- Dispose the list when you no longer need it: `users.dispose()`.
- For very large datasets, avoid creating one `RxState` per row up front.
  Use `RxPagedList`, or create row state lazily and release it when the row
  leaves the screen.

### Dependency injection

```dart
class UserController {
  final count = 0.obs;
}

RxDI.put(UserController());
final controller = RxDI.find<UserController>();
```

### Event bus

```dart
RxEventBus.on<String>(
  module: 'chat',
  eventID: 1,
  callback: (eventID, uuid, data) {
    print('收到事件: $data');
  },
);

RxEventBus.notify<String>(
  module: 'chat',
  eventID: 1,
  data: 'hello',
);
```

### Routing support

```dart
rxr.to('/detail/123?type=hot', arguments: MyData());
final id = rxr.param('id');
final type = rxr.queryItem('type');
```

## Quick start

Add the dependency:

```bash
flutter pub add rxflare
```

Then use it in your app:

```dart
import 'package:material_ui/material_ui.dart';
import 'package:rxflare/rxflare.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    final count = 0.obs;

    return MaterialApp(
      home: Scaffold(
        appBar: AppBar(title: const Text('rxflare demo')),
        body: Center(
          child: Rx(() => Text('count: ${count.value}')),
        ),
        floatingActionButton: FloatingActionButton(
          onPressed: () => count.value++,
          child: const Icon(Icons.add),
        ),
      ),
    );
  }
}
```

## Typical use cases

rxflare is well-suited for:

- form-heavy screens
- list and item-level updates
- modular app state
- event-driven UI updates
- small to medium Flutter apps that want less boilerplate
- teams that want explicit, flexible reactive state without heavyweight patterns
- very large lists backed by a database or paginated API

## Package structure

```text
lib/
  rxflare.dart              public entrypoint
  src/
    async/                 RxFuture and async state helpers
    collections/           reactive Map/List/Set wrappers and RxPagedList
    core/                  RxState, RxComputed, reactive base types
    di/                    RxDI and RxProvider
    rx_router/             routing support
    utils/                 debug and event bus utilities
    widgets/               Rx widgets and auto-dispose helpers
example/                   minimal example app
exampleIm/                showcase app
```

## Examples

The repository includes example projects and showcase demos:

- `example/` — a minimal Flutter sample 
- `exampleIm/` — a more complete interactive showcase   https://github.com/msfm2018/groupIm


## Documentation

- `README.md` — overview and quick usage
- `CHANGELOG.md` — version history
- `example/` — runnable sample code

## Repository status

rxflare is designed to be:

- lightweight
- reactive
- precise for UI updates
- easy to adopt in existing Flutter apps

## Contributing

Contributions, issues, and feature suggestions are welcome.

Please see [CONTRIBUTING.md](CONTRIBUTING.md) for development setup and contribution guidelines.

## License

This project is licensed under the MIT License. See [LICENSE](LICENSE) for details.

## Related projects

- [localMusicPlay](https://github.com/msfm2018/localMusicPlay)
- [simple_tree](https://github.com/msfm2018/simple_tree)

## Why it matters

A state library should not only be expressive — it should also be efficient.

rxflare focuses on the real bottleneck in many Flutter UIs: unnecessary rebuilds. By narrowing updates to the affected pieces of state, it helps apps stay responsive without introducing heavy architecture overhead.
