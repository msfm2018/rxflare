
import '../core/base_.dart';

/// Global dependency injection container.
///
/// Supports:
/// - Singleton registration
/// - Lazy registration
/// - Named instances
/// - Automatic disposal
class RxDI {
  static final Map<RxKey, Object> _singletonMap = {};
  static final Map<RxKey, Object Function()> _factoryMap = {};

  // ==================== Registration ====================

  /// Registers a singleton instance.
  ///
  /// Example:
  /// ```dart
  /// RxDI.put(UserController());
  /// ```

  static T put<T>(T dependency, {String? name}) {
    final key = RxKey(T, name);
    _singletonMap[key] = dependency as Object;
    return dependency;
  }

  /// Registers a lazy factory.
  ///
  /// The instance will be created only when first requested.
  ///
  /// Example:
  /// ```dart
  /// RxDI.lazyPut(
  ///   () => UserController(),
  /// );
  /// ```
  static void lazyPut<T>(T Function() builder, {String? name}) {
    final key = RxKey(T, name);
    _factoryMap[key] = builder as Object Function();
  }

  // ==================== Lookup ====================

  /// Finds a registered dependency.
  ///
  /// Throws if the dependency does not exist.

  static T find<T>({String? name}) {
    final result = _findInternal<T>(name: name, throwIfNotFound: true);
    return result as T;
  }

  /// Finds a registered dependency.
  ///
  /// Returns null if the dependency is not found.
  static T? findOrNull<T>({String? name}) {
    return _findInternal<T>(name: name, throwIfNotFound: false);
  }

  static T? _findInternal<T>({
    String? name,
    required bool throwIfNotFound,
  }) {
    final key = RxKey(T, name);

    final existing = _singletonMap[key];
    if (existing != null) {
      return existing as T;
    }

    // Lazy factory
    final factory = _factoryMap[key];
    if (factory != null) {
      final dep = factory();
      _singletonMap[key] = dep;
      _factoryMap.remove(key);
      return dep as T;
    }

    if (throwIfNotFound) {
      throw Exception(
        "Dependency not found: $key",
      );
    }

    return null;
  }

  // ==================== Removal ====================

  /// Removes a dependency from the container.
  ///
  /// If the instance implements [Disposable],
  /// its dispose method will be called automatically.

  static void delete<T>({String? name}) {
    final key = RxKey(T, name);

    final instance = _singletonMap[key];

    if (instance is Disposable) {
      instance.dispose();
    }

    _singletonMap.remove(key);
    _factoryMap.remove(key);
  }
}

// /// Widget-scoped dependency provider.
// ///
// /// Automatically registers a dependency when inserted
// /// into the widget tree and removes it when disposed.
// class RxProvider<T> extends StatefulWidget {
//   final T dependency;
//   final String? name;
//   final Widget child;

//   const RxProvider({
//     super.key,
//     required this.dependency,
//     this.name,
//     required this.child,
//   });

//   @override
//   State<RxProvider<T>> createState() => _RxProviderState<T>();
// }

// class _RxProviderState<T> extends State<RxProvider<T>> {
//   @override
//   void initState() {
//     super.initState();
//     RxDI.put<T>(widget.dependency, name: widget.name);
//   }

//   @override
//   void dispose() {
//     RxDI.delete<T>(name: widget.name);
//     super.dispose();
//   }

//   @override
//   Widget build(BuildContext context) => widget.child;
// }
