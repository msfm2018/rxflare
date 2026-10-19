# rxflare

A lightweight reactive state management library for Flutter, built for efficient UI updates with automatic dependency tracking and field-level precision.

[![Pub Version](https://img.shields.io/pub/v/rxflare.svg)](https://pub.dev/packages/rxflare)
[![License](https://img.shields.io/github/license/msfm2018/rxflare)](LICENSE)
[![Flutter](https://img.shields.io/badge/Flutter-3.0+-1EB7FF?logo=flutter&logoColor=white)]()
[![Platform](https://img.shields.io/badge/Platform-Android%20%7C%20iOS%20%7C%20Web%20%7C%20Desktop-4CAF50)]()

rxflare is designed for Flutter apps where UI updates need to stay fast and predictable. It reduces unnecessary rebuilds by tracking dependencies automatically and updating only the affected widgets or fields.

## Why rxflare?

Most reactive libraries focus on state values, but many UI problems come from over-rebuilding. rxflare solves that by making the reactive system precise:

- automatic dependency tracking
- field-level updates for Map and List
- computed values and derived state
- event-driven communication
- lightweight DI and controller support
- routing layer with `rxr`
- async state support with `RxFuture`

## Quick start

```bash
flutter pub add rxflare
```

```dart
import 'package:flutter/material.dart';
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
          child: Rx(() => Text('Count: ${count.value}')),
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

## Key features

### Reactive values

```dart
final count = 0.obs;
final name = 'Tom'.obs;

Rx(() => Text('${name.value}: ${count.value}'));
```

### Field-level updates

```dart
final user = {
  'name': 'Tom',
  'age': 25,
}.obs;

Rx(() => Text('Name: ${user.getItem('name')}'));
user.updateField('name', 'Jerry');
```

### Computed state

```dart
final price = 99.obs;
final quantity = 2.obs;

final total = computed(() => price.value * quantity.value);
Rx(() => Text('Total: ${total.value}'));
```

### DI and controller support

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
    print('Received: $data');
  },
);

RxEventBus.notify<String>(
  module: 'chat',
  eventID: 1,
  data: 'hello',
);
```

## Package structure

```text
lib/
  rxflare.dart              public API entrypoint
  src/
    async/                 RxFuture, async state helpers
    collections/           reactive Map/List/Set states
    core/                  RxState, computed, base logic
    di/                    RxDI, RxProvider
    rx_router/             navigation and routing utilities
    utils/                 event bus and debugging helpers
    widgets/               Rx widgets and auto-dispose tools
example/                   minimal sample app
exampleIm/                extended showcase app
```

## Documentation

- [CONTRIBUTING.md](CONTRIBUTING.md)
- [CHANGELOG.md](CHANGELOG.md)
- [LICENSE](LICENSE)

## Contributing

Contributions are welcome. Please read the [CONTRIBUTING.md](CONTRIBUTING.md) guide before opening a PR.

## License

MIT License. See [LICENSE](LICENSE) for details.

## Related projects

- [localMusicPlay](https://github.com/msfm2018/localMusicPlay)
- [simple_tree](https://github.com/msfm2018/simple_tree)
