# Changelog

## [1.6.6] - 2026-08-06

### Added
- **Internationalization (i18n) support** with `RxLocale`
  - Automatic system language detection (follows device locale)
  - Reactive translation with `.tr` and `.trParams`
  - Built-in fallback mechanism (exact match → language match → English)
  - Support for a wide range of languages and regional variants (zh_CN, zh_TW, zh_HK, en_US, en_GB, ja, ko, de, fr, es, pt_BR, etc.)
  - Lightweight implementation with zero third-party dependencies
  - Fully integrated with RxFlare's reactive system (auto rebuild on language change)

## [1.6.5] - 2026-07-25

### Added
- Added  demo exampleRoute


## [1.6.4] - 2026-06-18

### Added
- Added `RxState.runAsyncWithStatus()` for async state updates with loading and error handling.
- Added `RxState.runAsync()` with configurable retry logic and loading/error callbacks.

## [1.6.3] - 2026-06-12
### fixed log
## [1.6.2] - 2026-06-12

### Added
- Added `off(path, {arguments})` method to `RxRouter` to replace the current route with a new one.
- Added `offAll(path, {arguments})` method to `RxRouter` to clear the entire navigation stack and push a new root route.

### Changed
- Improved navigation stack management for declarative routing (Navigator 2.0).
## [1.6.1] - 2026-06-09

### Added

* Added `RxComputedExtensions`
  * Introduced `.v` shorthand for accessing `RxComputed.value`
  * Added `.current` alias for improved readability

* Added typed computed helper functions
  * `rxBool()` for creating `RxComputed<bool>`
  * `rxInt()` for creating `RxComputed<int>`
  * `rxString()` for creating `RxComputed<String>`
  * `rxDouble()` for creating `RxComputed<double>`

* Simplified computed value declarations
  * Reduces boilerplate when creating common computed types
  * Improves code readability and consistency with existing reactive APIs
## [1.6.0] - 2026-06-08

### Added

* Added `RxMaterialApp` — a convenient wrapper for `MaterialApp.router`
  * Automatically registers routes (`rxr.register`)
  * Automatically calls `ensureInitialized()`
  * No need to manually configure `routerDelegate` and `routeInformationParser`
  * Forwards most `MaterialApp.router` properties (`theme`, `builder`, `localizationsDelegates`, etc.)
  * Makes routing setup as simple as GoRouter

* Added `RxEventBus.once()`
  * Registers a one-time event listener
  * Automatically unregisters after the first event is received

### Breaking Changes
* Renamed several public APIs:
* `RxObjMgr` → `RxDI`
* `RxParent` → `RxProvider`
* `RxHiter` → `RxMatcher`
* `RxRes` → `RxResult`
* `RxDef` → `RxRoute`

### Improved

* Improved API naming consistency across routing, dependency injection, and event modules
* Updated public API names to better align with common Flutter ecosystem conventions

### Example

```dart
return Rx(() => RxMaterialApp(
  routes: AppRoutes.routes,
  initialRoute: "/",
  theme: ThemeData(...),
  darkTheme: ThemeData(...),
  themeMode: ThemeMode.light,
  // ... other properties
));

## [1.5.4] - 2026-06-02

### Added

* Added semantic and reactive query APIs for `RxList`:

  * `filter(bool Function(T) test)` → alias of `where`, improves readability for search scenarios
  * `maybeFirst(bool Function(T) test)` → safe nullable query
  * `find(bool Function(T) test)` → semantic alias of `firstWhere`
  * `findIndex(bool Function(T) test)` → index lookup with reactivity support

* Added reactive-safe batch update APIs:

  * `updateWhere(bool Function(T) test, T Function(T) update)`
  * `replaceWhere(bool Function(T) test, T newValue)`



## [1.5.3] - 2026-05-29

### Added
* Added list mutation APIs to improve usability and reactivity consistency:
  - `addAll(Iterable<T> items)`  
  - `insert(int index, T item)`  
  - `remove(T item) -> bool`  
  - `removeWhere(bool Function(T) test)`  
  - `clear()`  
  - `map<R>(R Function(T) toElement)`

### Behavior
* All mutating methods create a new `List<T>` instance to ensure reactive updates.
* `map()` preserves reactive context via `RxStack.register(this)`.

### Notes
* These APIs are designed for reactive state management scenarios where immutability is required for change detection.

## [1.5.2] - 2026-05-28
### Updated
* Upgraded `flutter_lints` to ^6.0.0 for improved code analysis.

## [1.5.1] - 2026-05-27

### Added
* **SafeComputed**: Introduced a safe computed wrapper to prevent crashes from runtime exceptions
  - Gracefully captures errors during computation
  - Separates `value` and `error` states for UI handling
  - Preserves last valid value when computation fails

### Improved
* **RxComputed Stability**:
  - Prevented potential re-entrant computation issues using internal lock
  - Improved dependency tracking consistency during rapid updates
* **Type Safety Enhancements**:
  - Improved nullable handling in computed states
  - Reduced unsafe casting patterns
* **Reactive UI Updates**:
  - Improved reactivity consistency when accessing nested/computed values

### Fixed
* Fixed potential self-dependency issue in computed (recursive dependency bug)
* Fixed unnecessary multiple rebuilds triggered by error state updates
* Fixed edge cases where computed could enter inconsistent state after exceptions

### Internal
* Refactored SafeComputed implementation for better separation of concerns
* Minor code cleanup and documentation improvements
## [1.5.0] - 2026-05-13

### Added
* **DevTools Extension**: Added a complete RxFlare State Monitoring Panel
  - Real-time viewing of all `RxState` (active status + current value)
  - Support for viewing `Computed` properties
  - Support for viewing DI Singletons
  - Added **Disposed** state tracking with visual distinction (marked in red)
* **DevTools Debugging Enhancements**:
  - `RxDI.initDevTools()` service extension registration
  - Improved `getDebugSnapshot()` with structured data support
  - `unregisterRx` + destroyed history recording functionality
* **Example Code**: Complete demo page (`HomePage`) with create, update, and destroy RxState demonstrations
* **RxFlare Inspector**: Standalone DevTools extension UI with auto-refresh (2-second polling)

### Improved
* More robust error handling and data formatting in `getDebugSnapshot()`
* Optimized `RxState` registration and disposal flow
* Enhanced DevTools panel display logic (status color coding, better readability)

### Fixed
* Data structure parsing issues in DevTools Extension
* Duplicate service extension registration problem


## [1.4.5] - 2026-05-11

### Added
* Introduced unified reactive extensions
## [1.4.5] - 2026-05-11
### Added
* Introduced unified reactive extensions:
* .obs → RxState
* .obsMap → RxMap
* .obsList → RxList
* .obsSet → RxSet
* Added convenient collection shortcuts:
* obsMapD for Map<String, dynamic> reactive mapping
### Improvement
* Improved developer ergonomics for reactive object creation
* Simplified common usage patterns for Map/List/Set observables
```
final user = {"name": "Tom", "age": 18}.obsMapD;

Rx(() {
  return Text(user["name"]); 
});

final todos = ["a", "b"].obsList();

todos[0] = "c";
```
## [1.4.4] - 2026-05-11
### Development package classification optimization

## [1.4.3] - 2026-05-10

### Added & Improved
*  Enhanced RxFuture with debounce, throttle, polling, and retry capabilities.
```
final userRx = RxFuture<User>(
  () => api.getUser(),
  debounce: Duration(milliseconds: 300),    // Debounce
  throttle: Duration(seconds: 1),           // Throttle
  maxRetries: 3,                            // Auto retry 3 times
  retryDelay: Duration(seconds: 1),         // Retry delay
  pollInterval: Duration(seconds: 10),      // Poll every 10 seconds
);


void main() {
  WidgetsFlutterBinding.ensureInitialized();
  
  // ========== Global RxFuture Configuration ==========
  RxFuture.globalOnError = (error, stack) {
    // 1. Unified logging
    // print("🌐 Global RxFuture error: $error\n$stack");
    
    // 2. Unified Toast / Dialog
    // print("Request failed: ${error.toString()}");
    
    // 3. Handle special cases (e.g. 401 token expiration)
    // if (error.toString().contains("401")) { ... }
  };

  runApp(const MyApp());
}
```
## [1.4.2] - 2026-05-10

### Added
* Improved examples and documentation.
* Added RxAutoDispose mixin – easily manage resource lifecycle by mixing into StatefulWidget.
```
class _UserPageState extends State<UserPage> with RxAutoDispose {
  final count = 0.obs;
  late final RxFuture<User> userFuture;

  @override
  void initState() {
    super.initState();

    userFuture = RxFuture(() async { ... }).autoDispose(this);

    count.listen((v) => print(v)).autoDispose(this);
  }

  @override
  Widget build(BuildContext context) { ... }
}
```
## [1.4.1] - 2026-05-09

### Improved

* Optimized route registration mechanism.
* Removed path parameter to make route registration cleaner and simpler.
* Enhanced RxFuture state listening.
* Added listenState() method to listen for internal state changes of RxFuture.
* Supported state transitions:
* loading → done
* loading → error
* Other state switches


* Useful for actively refreshing the UI when state changes.

## [1.4.0] - 2026-05-08

### Added

*  RxCollections Enhancement: Introduced RxList, RxSet, and rx_map to simplify collection state management through immutable updates.

* RxList：
* Supports native List syntax: read via [] and modify via [] =
* Automatic reactivity: add, removeAt, updateAt operations automatically create new List instances and trigger updates.

* 示例：
```
Dart
  final todos = RxList<String>(["Learn Flutter"]);
  todos.add("Build app"); // 自动触发 UI 刷新
  todos[0] = "Master Flutter"; // 运算符重载支持
```

## [1.3.1] - 2026-04-28

### Added

* Introduced RxBuilder widget: a standard StatelessWidget wrapper for reactive partial UI updates.

* 
```
Dart
RxBuilder(
  builder: (context) => Text('当前计数: ${count.value}'),
)
```
## [1.3.0] - 2026-04-25

### Added


*  Introduced new reactive routing system RxRouter: A Navigator 2.0 based routing solution driven by RxState.

### Key Features:

*  Multi-stack management (global root stack + independent tab stacks)
*  Unified declarative and imperative API (rxr.to('/path'), rxr.back())
*  Dynamic path matching (/user/:id) and query parameter parsing
*  Route guards (async interceptors for auth, permission control, etc.)
*  Strongly typed arguments passing with automatic lifecycle management
*  Asynchronous result callback (to<T>() returns Future<T?>)
*  Full Web support (browser URL sync)
*  Built-in KeepAliveWrapper for better Tab page state preservation

## [1.2.0] - 2026-04-18
### Added
* New generic extension RxAnyExtension<T> – convert any object to RxState<T> using .obs:
  ```dart
  final user = User().obs;
  final count = 1.obs;
  ```
* Unified .obs usage, reducing redundant extensions for primitive types.

## [1.1.9] - 2026-04-08
* Improved documentation readability.

## [1.1.8] - 2026-04-07
* Completed API documentation comments.
* Improved documentation readability.

## [1.1.7] - 2026-04-07
* Fixed errors in example code.

## [1.1.6] - 2026-04-07
* Completed the example project.

## [1.1.5] - 2026-04-05
* Optimized nested dependency handling logic.
  ```dart
  RxA(() {
    RxB(() {
      // Nested dependency support
    });
  });
  ```

## [1.1.4] -2026-04-01

* Added examples for updating list fields and map fields.

# Changelog

## [1.1.3] - 2026-03-28
* Fixed analyzer warnings to improve package health.
* Improved type safety in `rx_get`.
* Cleaned up documentation comments for better IDE support.

## [1.1.1] - 2026-03-21
### Changed
* Updated core reactive logic and improved performance.

## [1.0.0] - 2026-03-18
### Added
* Added listen interface to support data change listening.
* Official stable release of version 1.0.0.

## [0.0.4] - 2026-03-10
* Improved and optimized demo code.

## [0.0.3] - 2026-03-05
### Added
* Added core reactive components：`rx_event_simple`, `rx_future`, `RxValue<T>`, `RxStore<T>`, `RxNotifier<T>`。
* Added custom demo project.

## [0.0.1] - 2025-06-04
* Initial release of rxflare.