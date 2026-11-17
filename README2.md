# rxflare

A lightweight reactive state management library for Flutter, built for high-performance UI updates with automatic dependency tracking and field-level precision.

[![Pub Version](https://img.shields.io/pub/v/rxflare.svg)](https://pub.dev/packages/rxflare)
[![License](https://img.shields.io/github/license/msfm2018/rxflare)](LICENSE)
[![Flutter](https://img.shields.io/badge/Flutter-3.0+-1EB7FF?logo=flutter&logoColor=white)](https://flutter.dev)
[![Platform](https://img.shields.io/badge/Platform-Android%20%7C%20iOS%20%7C%20Web%20%7C%20Desktop-4CAF50)](https://flutter.dev)

```yaml
dependencies:
  rxflare: ^2.0.0
```

rxflare helps Flutter applications build reactive state with less boilerplate and more precise UI updates.

Instead of rebuilding an entire screen when a single field changes, rxflare automatically tracks dependencies and updates only the relevant widget subtree.

**Key benefits:**

- Automatic dependency tracking
- Fine-grained reactive updates
- Minimal unnecessary widget rebuilds
- Unified and strongly typed reactive APIs
- Modular architecture
- Lightweight and developer-friendly APIs

---

## 1. Introduction

rxflare is a reactive state management library designed to simplify state management in Flutter applications.

Its reactive engine tracks which values are accessed during widget execution and establishes dependencies automatically.

When a reactive value changes, only the widgets that depend on that value are notified.

Unlike traditional approaches that often rely on manually managing listeners or rebuilding large widget subtrees, rxflare provides a more direct and expressive programming model.

```dart
final count = 0.rx;

Rx(() => Text('Count: ${count.value}'));
```

No manual subscription or listener registration is required.

## 2. Packages

Starting from 2.0.0, rxflare adopts a modular multi-package architecture.

Each package has a clearly defined responsibility.

| Package | Description |
|---|---|
| [rxflare](https://pub.dev/packages/rxflare) | Complete solution combining state management, routing, and internationalization |
| [rxflare_core](https://pub.dev/packages/rxflare_core) | Reactive state management and core utilities |
| [rxflare_router](https://pub.dev/packages/rxflare_router) | Navigation and routing |
| [rxflare_i18n](https://pub.dev/packages/rxflare_i18n) | Reactive internationalization |

**Recommended installation**

For most applications, use the umbrella package:

```yaml
dependencies:
  rxflare: ^2.0.0
```

If you only need reactive state management, install the core package:

```yaml
dependencies:
  rxflare_core: ^2.0.0
```

You can also install routing and internationalization independently.

All packages are maintained in one monorepo:

[github.com/msfm2018/rxflare](https://github.com/msfm2018/rxflare)

## 3. Why rxflare?

If you are tired of managing large state objects and rebuilding entire screens for small state changes, rxflare is designed for you.

rxflare provides:

- Unified `.rx` API for reactive values.
- Strongly typed reactive collections.
- Automatic dependency tracking.
- Field-level updates for maps and collections.
- `computed` for derived reactive values.
- `effect` and `watch` for reactive side effects.
- `batch` and `untracked` for controlling dependency tracking and updates.
- Lightweight dependency injection.
- Optional routing and internationalization packages.
- Async helpers such as `RxFuture`.
- Event-driven communication with `RxEventBus`.
- Paginated reactive lists with `RxPagedList`.

The goal is simple:

**Write less state management code while keeping UI updates precise and efficient.**

## 4. Quick Start

Install rxflare:

```bash
flutter pub add rxflare
```

Import the package:

```dart
import 'package:rxflare/rxflare.dart';
```

Create your first reactive application:

```dart
void main() => runApp(const MyApp());

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    final count = 0.rx;

    return MaterialApp(
      home: Scaffold(
        appBar: AppBar(
          title: const Text('rxflare demo'),
        ),
        body: Center(
          child: Rx(
            () => Text('Count: ${count.value}'),
          ),
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

That's it.

The `Rx` widget automatically tracks `count.value` and rebuilds when the value changes.

## 5. Core Features

### 5.1 Reactive State

Use `.rx` to convert any value into an `RxState<T>`.

```dart
final count = 0.rx;
final name = 'Tom'.rx;
final isLoading = false.rx;

count.value++;
name.value = 'Jerry';
isLoading.value = true;
```

You can use reactive state with primitive values, objects, lists, maps, and other Dart types.

### 5.2 Precise Field-Level Updates

rxflare supports fine-grained dependency tracking for reactive maps.

```dart
final user = {
  'name': 'Tom',
  'age': 25,
}.rx;

Rx(
  () => Text(
    'Name: ${user.getItem('name')}',
  ),
);

user.updateField('name', 'Jerry');
```

The widget tracks the accessed field rather than subscribing indiscriminately to every field.

This helps reduce unnecessary rebuilds when working with complex state objects.

### 5.3 Computed Values

Use `computed()` to create derived reactive values.

```dart
final price = 99.rx;
final quantity = 2.rx;

final total = computed(
  () => price.value * quantity.value,
);

Rx(
  () => Text('Total: ${total.value}'),
);
```

When either `price` or `quantity` changes, the computed value updates automatically.

### 5.4 Batch Updates

Use `batch()` to group multiple reactive updates into a single notification cycle.

```dart
final firstName = ''.rx;
final lastName = ''.rx;
final age = 0.rx;

batch(() {
  firstName.value = 'Ada';
  lastName.value = 'Lovelace';
  age.value = 36;
});
```

Batching helps avoid redundant notifications when several values are updated together.

### 5.5 Untracked Reads

Use `untracked()` to read reactive values without collecting dependencies.

```dart
final name = 'Tom'.rx;
final id = 100.rx;

final label = computed(() {
  final currentName = name.value;

  final debugId = untracked(
    () => id.value,
  );

  return '$currentName ($debugId)';
});
```

The computed value tracks `name`, but does not subscribe to `id`.

### 5.6 Effects and Watch

Use `effect()` for automatically tracked side effects.

```dart
final count = 0.rx;

final stop = effect(() {
  debugPrint('Count: ${count.value}');
});

// Stop listening when no longer needed.
stop();
```

Use `watch()` when you need to observe changes in derived values.

```dart
final stopWatch = watch(
  () => count.value,
  (value) {
    debugPrint('Watched: $value');
  },
);

// Dispose the watcher.
stopWatch();
```

Both APIs return disposal functions so that subscriptions can be released when they are no longer needed.

## 6. Reactive Values & Collections

rxflare provides a unified `.rx` API for reactive values and specialized extensions for strongly typed collections.

### 6.1 Reactive Values

Use `.rx` to convert any value into an `RxState<T>`.

```dart
final count = 0.rx;
final name = 'Tom'.rx;
final isLoading = false.rx;

final numbers = <int>[1, 2, 3].rx;
```

The resulting type is `RxState<T>`.

For example:

```dart
final numbers = <int>[1, 2, 3].rx;

// RxState<List<int>>
```

### 6.2 Reactive List

Use `.rxList` to create an `RxList<T>`.

```dart
final todos = <String>[
  'Learn Dart',
  'Build Flutter apps',
].rxList;
```

### 6.3 Reactive Map

Use `.rxMap` to create an `RxMap<K, V>`.

```dart
final user = <String, Object?>{
  'name': 'Tom',
  'age': 25,
}.rxMap;
```

### 6.4 Reactive Set

Use `.rxSet` to create an `RxSet<T>`.

```dart
final tags = <String>{
  'Flutter',
  'Dart',
}.rxSet;
```

### 6.5 Reactive JSON Map

Use `.rxMapD` for JSON-friendly maps.

```dart
final config = <String, dynamic>{
  'theme': 'dark',
  'language': 'en',
}.rxMapD;
```

The resulting type is:

```dart
RxMap<String, dynamic>
```

### 6.6 Reactive List of JSON Objects

Use `.rxListMap` for lists containing JSON objects.

```dart
final users = <Map<String, dynamic>>[
  {
    'name': 'Tom',
    'age': 25,
  },
  {
    'name': 'Jerry',
    'age': 30,
  },
].rxListMap;
```

The resulting type is:

```dart
RxList<Map<String, dynamic>>
```

### 6.7 Boolean Utilities

`RxState<bool>` provides a convenient `toggle()` method.

```dart
final isExpanded = false.rx;

isExpanded.toggle();

print(isExpanded.value); // true
```

### 6.8 Choosing the Right API

| API | Resulting Type | Use Case |
|---|---|---|
| `.rx` | `RxState<T>` | General reactive values |
| `.rxList` | `RxList<T>` | Reactive lists |
| `.rxMap` | `RxMap<K, V>` | Reactive maps |
| `.rxSet` | `RxSet<T>` | Reactive sets |
| `.rxMapD` | `RxMap<String, dynamic>` | JSON maps |
| `.rxListMap` | `RxList<Map<String, dynamic>>` | Lists of JSON objects |

**Important:** `.rx` and `.rxList` are different APIs.

- `.rx` wraps a collection inside `RxState<T>`.
- `.rxList` creates a dedicated `RxList<T>` with collection-level reactive behavior.

Choose the API according to your update and dependency-tracking requirements.

## 7. Automatic Dependency Tracking

Automatic dependency tracking is one of the core features of rxflare.

When an `Rx` widget executes its callback, rxflare automatically tracks the reactive values accessed during that execution.

Example:

```dart
final name = 'Tom'.rx;
final age = 25.rx;

Rx(() {
  return Text('Name: ${name.value}');
});
```

The widget depends on `name`, but does not depend on `age`.

Updating `name` triggers the corresponding reactive update:

```dart
name.value = 'Jerry';
```

Updating `age` does not trigger this widget:

```dart
age.value = 30;
```

No manual listener registration or dependency declaration is necessary.

This makes reactive dependencies explicit through ordinary value access.

## 8. Computed Values, Effects & Watch

rxflare provides three important reactive tools for managing derived state and side effects.

| API | Purpose |
|---|---|
| `computed()` | Creates derived reactive values |
| `effect()` | Automatically tracks dependencies and executes side effects |
| `watch()` | Observes reactive sources and responds to changes |

Example:

```dart
final firstName = 'Ada'.rx;
final lastName = 'Lovelace'.rx;

final fullName = computed(
  () => '${firstName.value} ${lastName.value}',
);

final stop = effect(() {
  debugPrint('Full name: ${fullName.value}');
});

final stopWatch = watch(
  () => fullName.value,
  (value) {
    debugPrint('Name changed: $value');
  },
);
```

Dispose reactive subscriptions when they are no longer required:

```dart
stop();
stopWatch();
```

## 9. Large Paginated Lists

`RxList` keeps its collection data in memory. For datasets containing hundreds of thousands or millions of records, loading everything at once may be inefficient.

`RxPagedList` provides page-based loading, caching, and index-level reactivity.

Example:

```dart
final users = RxPagedList<User>(
  pageSize: 50,
  maxCachedPages: 20,
  loader: (page, size) async {
    final response = await api.fetchUsers(
      page: page,
      size: size,
    );

    return PageResult(
      response.items,
      totalCount: response.total,
    );
  },
);
```

Build a reactive list:

```dart
Rx(
  () => ListView.builder(
    itemCount: users.length,
    itemExtent: 64,
    itemBuilder: (_, index) => Rx(() {
      if (users.statusAt(index) == RxPageStatus.error) {
        return TextButton(
          onPressed: () {
            users.retryPage(
              index ~/ users.pageSize,
            );
          },
          child: const Text('Retry'),
        );
      }

      final user = users[index];

      return user == null
          ? const SkeletonTile()
          : UserTile(user);
    }),
  ),
);
```

Update one cached item:

```dart
users.updateAt(3, updatedUser);
```

Only the row observing the affected index needs to update.

Invalidate and reload the cache:

```dart
await users.invalidate();
```

### Features

- Lazy page loading with configurable `pageSize`, `prefetch`, and `maxConcurrent`.
- LRU page cache with configurable `maxCachedPages`.
- Observed pages are protected from eviction.
- Index-level reactive updates.
- Loading and error states through `statusAt()` and `errorAt()`.
- Manual page retry through `retryPage()`.
- Duplicate request prevention.
- Stale response protection after invalidation.
- Known-total mode with `PageResult(items, totalCount: n)`.
- Infinite-scroll mode when `totalCount` is omitted.

### Notes

- Read `list[index]` inside each row's own `Rx`, rather than reading every item in the outer widget.
- Configure `maxCachedPages` according to the visible page count and prefetch requirements.
- `updateAt()` updates the local cache; persist changes to your backend separately.
- Inserting or removing items changes subsequent page boundaries. Use `invalidate()` when the underlying dataset changes.
- Call `users.dispose()` when the paginated list is no longer needed.
- Avoid creating one `RxState` for every row in a very large dataset up front. Prefer lazy creation and proper disposal.

## 10. Dependency Injection & Event Bus

### 10.1 Dependency Injection

rxflare includes a lightweight dependency injection system through `RxDI`.

```dart
class UserController {
  final count = 0.rx;
}

void setup() {
  RxDI.put(UserController());
}

final controller = RxDI.find<UserController>();
```

This allows application components to access shared dependencies without manually passing them through every widget.

### 10.2 Event Bus

Use `RxEventBus` for communication between independent application components.

Subscribe to an event:

```dart
RxEventBus.on<String>(
  module: 'chat',
  eventID: 1,
  callback: (eventID, uuid, data) {
    debugPrint('Event: $data');
  },
);
```

Publish an event:

```dart
RxEventBus.notify<String>(
  module: 'chat',
  eventID: 1,
  data: 'hello',
);
```

This is useful for decoupled communication between modules, controllers, and services.

## 11. Routing & Internationalization

rxflare 2.0 separates routing and internationalization into independent packages.

### 11.1 Routing

Use `rxflare_router` for application navigation.

```dart
rxr.to(
  '/detail/123?type=hot',
  arguments: MyData(),
);

final id = rxr.param('id');
final type = rxr.queryItem('type');
```

You can also use the style-agnostic `RxWidgetsApp`:

```dart
RxWidgetsApp(
  routes: {
    '/': RxRoute(
      builder: () => const HomePage(),
    ),
    '/detail/:id': RxRoute(
      builder: () => const DetailPage(),
    ),
  },
  initialRoute: '/',
);
```

Provide Material, Cupertino, or other application theming at the application level as needed.

For routing-only projects:

```yaml
dependencies:
  rxflare_router: ^2.0.0
```

### 11.2 Internationalization

Use `rxflare_i18n` for reactive localization.

```yaml
dependencies:
  rxflare_i18n: ^2.0.0
```

The localization package is maintained independently from the core reactive engine.

See the package documentation and examples for initialization, translation resources, language switching, and persistence.

## 12. Performance

rxflare is designed for high-frequency state updates with minimal overhead.

The following micro-benchmarks compare common Flutter state management solutions under different workloads.

Test environment: Windows, release mode.

### 12.1 Pure Write (No Listeners)

1,000,000 writes of a simple integer counter.

| Library | Average (µs / write) |
|---|---:|
| **RxFlare (RxState)** | **0.0030** |
| ChangeNotifier | 0.0048 |
| ValueNotifier | 0.0055 |
| Bloc Cubit | 0.0073 |
| GetX (RxInt) | 0.0082 |
| Signals | 0.0111 |
| MobX | 0.0993 |
| Riverpod (Notifier) | 0.7664 |

### 12.2 Write with Listeners

1,000,000 writes with 0, 1, and 10 active listeners.

| Library | 0 Listeners | 1 Listener | 10 Listeners |
|---|---:|---:|---:|
| **RxFlare** | **0.0024** | **0.0063** | 0.0291 |
| ChangeNotifier | 0.0051 | 0.0068 | **0.0268** |
| ValueNotifier | 0.0064 | 0.0090 | 0.0279 |
| GetX | 0.0099 | 0.0158 | 0.0819 |
| Bloc Cubit | 0.0075 | 0.0423 | 0.4138 |
| Signals | 0.0132 | 0.0570 | 0.2943 |
| MobX | 0.1067 | 0.1989 | 0.6801 |
| Riverpod | 0.8277 | 0.8283 | 1.0515 |

### 12.3 Real UI Rebuild (Batched Updates)

20,000 state updates that trigger actual widget rebuilds.

No per-frame wait is used, avoiding synchronization with the 16.7 ms display refresh interval.

| Library | 1 Widget (µs) | 10 Widgets (µs) |
|---|---:|---:|
| Signals (Watch) | **1.771** | 2.452 |
| ValueNotifier | 2.411 | 2.493 |
| MobX (Observer) | 2.469 | **2.446** |
| ChangeNotifier | 2.488 | 2.497 |
| GetX (Obx) | 2.490 | 2.499 |
| **RxFlare (Rx)** | 2.598 | 2.512 |
| Bloc Cubit | 2.502 | 4.204 |
| Riverpod | 3.321 | 3.384 |

*Unit: µs / write. Lower is better.*

### Summary

| Scenario | Strong performers |
|---|---|
| Pure write | RxFlare, ChangeNotifier, ValueNotifier |
| Write + listeners | RxFlare, ChangeNotifier, ValueNotifier |
| Real UI rebuild | Signals, ValueNotifier, MobX, RxFlare |

### Benchmark Notes

These micro-benchmarks focus on state update and notification overhead.

Actual application performance also depends on:

- Widget tree depth.
- Widget build complexity.
- Dependency tracking overhead.
- Number of active listeners.
- Collection size and access patterns.
- Application architecture and usage patterns.

Benchmark source code is available in the repository.

## 13. Migration from 1.x to 2.0

Version 2.0 introduces a modular package architecture and several API changes.

### 13.1 Package Migration

| Change | Action |
|---|---|
| Package split | Use `rxflare: ^2.0.0` or install individual packages |
| Core state management | Use `rxflare_core` |
| Routing | Use `rxflare_router` |
| Internationalization | Use `rxflare_i18n` |

### 13.2 API Migration

| Legacy API | Recommended API |
|---|---|
| `count.obs` | `count.rx` |
| `list.obsList` | `list.rxList` |
| `map.obsMap` | `map.rxMap` |
| `set.obsSet` | `set.rxSet` |
| `map.obsMapD` | `map.rxMapD` |
| `list.obsListMap` | `list.rxListMap` |

Legacy extensions are deprecated but retained for backward compatibility.

Use the new `.rx` naming convention in new code.

### 13.3 Removed APIs

| Legacy API | Migration |
|---|---|
| `RxObjMgr` | Use `RxDI` |
| `RxParent` | Use `RxProvider` where applicable |
| `RxMaterialApp` | Use `RxWidgetsApp` with your own application shell |

`RxObjMgr` and `RxParent` have been removed in 2.0.

### 13.4 Reactive Update Migration

- `effect()` provides automatic dependency tracking and returns a disposal function.
- `watch()` provides reactive observation and returns a disposal function.
- Use `batch()` when multiple state changes should be grouped together.
- Use `untracked()` when reading reactive values without collecting dependencies.

See [MIGRATION.md](MIGRATION.md) for complete migration instructions and refresh timing details.

## 14. Repository & Examples

### Repository Layout

```text
rxflare/
│
├── packages/
│   ├── rxflare_core/
│   │   ├── reactive state
│   │   ├── Rx
│   │   ├── computed
│   │   ├── effect / watch
│   │   ├── batch / untracked
│   │   ├── collections
│   │   └── dependency injection
│   │
│   ├── rxflare_router/
│   │   └── routing and navigation
│   │
│   ├── rxflare_i18n/
│   │   └── localization
│   │
│   └── rxflare/
│       └── umbrella package
│
├── example/
├── exampleIm/
│
├── MIGRATION.md
├── CHANGELOG.md
├── PUBLISH.md
└── README.md
```

### Examples

Explore the example projects:

- [example/](example/) — Minimal Flutter sample.
- [exampleIm/](exampleIm/) — Interactive feature showcase.
- [groupIm](https://github.com/msfm2018/groupIm) — Related project.

### Documentation

| Document | Description |
|---|---|
| [README.md](README.md) | Overview and usage |
| [MIGRATION.md](MIGRATION.md) | Migration from 1.x to 2.0 |
| [CHANGELOG.md](CHANGELOG.md) | Version history |
| [PUBLISH.md](PUBLISH.md) | Publishing instructions |

## 15. Contributing, License & Related Projects

### Contributing

Contributions, bug reports, and feature suggestions are welcome.

If you find a bug or have an idea for improvement, feel free to open an issue or submit a pull request.

[Contribute on GitHub](https://github.com/msfm2018/rxflare)

### License

rxflare is released under the MIT License.

See [LICENSE](LICENSE) for details.

### Related Projects

Other projects maintained by the author:

- [localMusicPlay](https://github.com/msfm2018/localMusicPlay)
- [simple_tree](https://github.com/msfm2018/simple_tree)

---

## Why It Matters

A state management library should not only be expressive — it should also be efficient.

rxflare focuses on a common Flutter development challenge: unnecessary widget rebuilds.

By automatically tracking reactive dependencies and narrowing updates to the affected parts of the UI, rxflare aims to make Flutter applications more responsive without introducing unnecessary architectural complexity.

**Less boilerplate. More precise updates. Better reactive development.**

