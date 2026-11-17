# Reactive collections and paginated data

Source of truth:
- `rxflare_core/lib/src/collections/rx_list.dart`
- `rxflare_core/lib/src/collections/rx_map.dart`
- `rxflare_core/lib/src/collections/rx_set.dart`
- `rxflare_core/lib/src/collections/rx_paged_list.dart`
- corresponding tests under `rxflare_core/test/`

## Collection constructors

```dart
final todos = <String>['A', 'B'].rxList;
final scores = <String, int>{'math': 90}.rxMap;
final tags = <String>{'flutter', 'dart'}.rxSet;
final json = <String, dynamic>{'name': 'Ada'}.rxMapD;
final rows = <Map<String, dynamic>>[{'id': 1}].rxListMap;

// Legacy aliases remain available but are deprecated:
// .rxList, .rxMap, .rxSet, .rxMapD, .rxListMap
```

Alternatively construct explicitly:

```dart
final todos = RxList<String>(['A', 'B']);
final scores = RxMap<String, int>({'math': 90});
final tags = RxSet<String>({'flutter', 'dart'});
```

## RxList

`RxList<T>` extends `RxState<List<T>>`.

Index reads register a field-level dependency:

```dart
Rx(() => Text(todos[0]));
todos[0] = 'Updated';
```

Other available operations include `where`, `filter`, `maybeFirst`, `find`, `findIndex`, `safeIndex`, `firstWhere`, `firstWhereOrNull`, `singleWhere`, `indexWhere`, `contains`, `updateAt`, `updateWhere`, `replaceWhere`, `add`, `addAll`, `insert`, `remove`, `removeWhere`, `removeAt`, `clear`, `map`, `length`, and `list`.

`list` returns the underlying List; direct mutation through that reference does not trigger reactivity. Use the provided mutation methods.

Whole-list operations such as `add`, `remove`, `clear`, and `value = newList` trigger global state notifications. Index assignment (`list[index] = value`) uses a field-level update and notifies listeners of that index.

**Audit caveat:** `updateWhere` and `replaceWhere` currently assign through `value` and then notify changed indexes, so global listeners are notified too. `updateAt` currently ignores its `notifyGlobal` argument. Do not claim these operations are strictly index-only until fixed and covered by tests.

## RxMap

```dart
final user = <String, String>{'name': 'Ada'}.rxMap;

Rx(() => Text(user['name'] ?? ''));
user['name'] = 'Grace';
```

A key read registers both a state dependency and a field dependency in the current implementation. A key write compares values with `deepEquals`, copies the Map, and sends a field-level notification for that key.

## RxSet

```dart
final selected = <int>{1, 2}.rxSet;

Rx(() => Text('${selected.length} selected'));
selected.add(3);
selected.remove(1);
```

Available reactive reads include `contains`, `length`, `isEmpty`, `isNotEmpty`, and `set`. `set` returns an unmodifiable view. `add` and `remove` copy the Set and update the RxState only when membership changes.

## RxPagedList

Use `RxPagedList<T>` when data should be loaded and cached page by page rather than retaining a very large List in memory.

```dart
final users = RxPagedList<User>(
  pageSize: 50,
  maxCachedPages: 20,
  loader: (page, size) async {
    final response = await api.fetchUsers(page: page, size: size);
    return PageResult<User>(
      response.items,
      totalCount: response.total,
    );
  },
);
```

`PageLoader<T>` is `Future<PageResult<T>> Function(int page, int pageSize)`. `PageResult` accepts `items`, optional `totalCount`, and optional `hasMore`.

Important public members include:
- `pageSize`, `maxCachedPages`, `prefetch`, `maxConcurrent`
- `length` (reactive count) and `peekLength` (non-tracking count)
- `cachedPages`, `hasMore`
- `operator []`, `statusAt`, `errorAt`, `peek`
- `updateAt`, `ensureLoaded`, `retryPage`, `invalidate`, `dispose`

Render each row in its own `Rx` so the row subscribes to its own index:

```dart
Rx(() => ListView.builder(
  itemCount: users.length,
  itemBuilder: (context, index) => Rx(() {
    final status = users.statusAt(index);
    final user = users[index];

    if (status == RxPageStatus.error) {
      return TextButton(
        onPressed: () => users.retryPage(index ~/ users.pageSize),
        child: const Text('Retry'),
      );
    }

    return user == null
        ? const CircularProgressIndicator()
        : UserTile(user: user);
  }),
));
```

The outer builder should read `users.length` for count changes; avoid reading every `users[index]` in the outer builder. `peek(index)` reads cached data without registering a dependency or triggering a load. `updateAt` updates only an already-cached row and returns `false` if the page/item is not cached.

Call `invalidate()` when filters or page boundaries change. Dispose the list when its owner no longer needs it.

## Equality and nested mutation

The current `RxState.deepEquals` uses shallow `mapEquals` / `listEquals` for Maps and Lists. Mutating nested objects in place is not a reliable way to trigger a change. Prefer replacing the relevant value or using the collection API.
