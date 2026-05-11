# Changelog
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