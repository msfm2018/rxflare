# rxflare 交流 qq群 246233219

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

Rx(() => Text('总价: ${total.value}'));
```

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

## Package structure

```text
lib/
  rxflare.dart              public entrypoint
  src/
    async/                 RxFuture and async state helpers
    collections/           reactive Map/List/Set wrappers
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
- `exampleIm/` — a more complete interactive showcase

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
