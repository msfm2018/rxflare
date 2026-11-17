# RxEventBus

Source of truth:
- `rxflare_core/lib/src/utils/rx_event_bus.dart`
- `rxflare_core/lib/src/widgets/rx_auto_dispose.dart`

Import:

```dart
import 'package:rxflare_core/rxflare_core.dart';
```

## Subscribe and publish

Events are identified by a `module` string and integer `eventID`. Payloads are generic:

```dart
final token = EventToken();

RxEventBus.on<String>(
  module: 'chat',
  eventID: 1,
  token: token,
  callback: (eventID, uuid, message) async {
    debugPrint('[$eventID][$uuid] $message');
  },
);

RxEventBus.notify<String>(
  module: 'chat',
  eventID: 1,
  data: 'Hello',
);
```

`EventCallback<T>` is `Future<void> Function(int eventID, String uuid, T data)`. `notify` accepts an optional `uuid`, `EventPriority`, `parallel`, `sticky`, and `delay`.

## One-time listeners

```dart
RxEventBus.once<String>(
  module: 'chat',
  eventID: 2,
  callback: (eventID, uuid, message) async {
    debugPrint(message);
  },
);
```

The wrapper removes itself before invoking the supplied callback.

## Sticky events

```dart
RxEventBus.notify<String>(
  module: 'chat',
  eventID: 3,
  data: 'latest status',
  sticky: true,
);

RxEventBus.on<String>(
  module: 'chat',
  eventID: 3,
  sticky: true,
  callback: (eventID, uuid, value) async {
    debugPrint(value);
  },
);
```

A sticky subscription schedules delivery of the latest cached payload when one exists. Sticky cache is global and keyed by module/event ID.

## Priority and dispatch mode

`EventPriority` values are `high`, `normal`, and `low`. The internal queue sorts tasks by priority. `parallel: true` (the default) dispatches to the listeners concurrently; `parallel: false` awaits listeners sequentially. Callback errors are caught and logged by the dispatcher.

`notify` is a void API and queues dispatch; it does not return a Future that callers can await for listener completion.

## Unsubscribe and cleanup

```dart
RxEventBus.off(
  module: 'chat',
  eventID: 1,
  callback: myCallback,
);

RxEventBus.offByToken(token);
RxEventBus.clearAll();
```

`off` removes all listeners for a module/event when `callback` is omitted, or removes the matching callback when supplied. `offByToken` removes registrations associated with that token. `clearAll` clears listeners, sticky values, and pending tasks; use it carefully because it affects the global bus.

Register token cleanup with a `State`:

```dart
final token = EventToken().autoDispose(this);
```

Or create a token already registered with an `RxAutoDispose` host using `autoDisposeToken()`.

## Cautions

- The bus is static/global, not scoped to a widget subtree.
- Use stable callback references if you later need to remove a listener by callback.
- A token is safer when subscription ownership is tied to a lifecycle.
- Do not assume event delivery completion from the return of `notify()`.
