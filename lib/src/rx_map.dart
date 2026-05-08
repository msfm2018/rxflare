import 'rx_state.dart';

/// A reactive Map state container.
///
/// [RxMap] is a specialized reactive state class for managing `Map<K, V>` data.
///
/// Compared to using `RxState<Map<K, V>>` directly, this class provides:
///
/// - Native Map-like syntax (`[]`, `[]=`)
/// - Immutable update behavior
/// - Automatic reactive notifications
/// - Better readability and maintainability
///
/// ## Example
///
/// ```dart
/// final user = RxMap<String, dynamic>({
///   "name": "Tom",
///   "age": 18,
/// });
///
/// user["name"] = "Jerry";
///
/// print(user["name"]); // Jerry
/// ```
///
/// ## Reactive Usage
///
/// ```dart
/// Rx(() {
///   return Text(user["name"]);
/// });
/// ```
///
/// Updating only the changed key can help build
/// fine-grained reactive systems with minimal rebuilds.
///
/// ## Notes
///
/// Internally, [RxMap] uses immutable updates:
///
/// ```dart
/// final newMap = Map<K, V>.of(value);
/// ```
///
/// This ensures Flutter widgets and reactive systems
/// can correctly detect state changes.
class RxMap<K, V> extends RxState<Map<K, V>> {
  /// Creates a reactive map state.
  ///
  /// The [initial] parameter defines the initial map value.
  ///
  /// Optional parameters:
  ///
  /// - [id]: Unique identifier for debugging or dependency tracking.
  /// - [name]: Friendly debug name shown in logs.
  ///
  /// ## Example
  ///
  /// ```dart
  /// final settings = RxMap<String, bool>({
  ///   "darkMode": false,
  /// });
  /// ```
  RxMap(
    super.initial, {
    super.id,
    super.name,
  });

  /// Returns the value associated with [key].
  ///
  /// Behaves like a normal Dart Map getter.
  ///
  /// ## Example
  ///
  /// ```dart
  /// final name = user["name"];
  /// ```
  V? operator [](K key) => value[key];

  /// Updates the value of [key].
  ///
  /// This operation performs an immutable update
  /// and automatically triggers reactive notifications.
  ///
  /// ## Example
  ///
  /// ```dart
  /// user["name"] = "Alice";
  /// ```
  ///
  /// Equivalent to:
  ///
  /// ```dart
  /// user.updateAt("name", "Alice");
  /// ```
  void operator []=(K key, V newValue) {
    final newMap = Map<K, V>.of(value);

    newMap[key] = newValue;

    value = newMap;
  }

  /// Updates the value at the specified [key].
  ///
  /// This method is recommended when you want
  /// more explicit update semantics.
  ///
  /// Internally this creates a new immutable Map instance
  /// to ensure reactive listeners are notified correctly.
  ///
  /// ## Example
  ///
  /// ```dart
  /// user.updateAt("age", 20);
  /// ```
  ///
  /// The optional [notifyGlobal] parameter is reserved
  /// for future fine-grained/global notification strategies.
  void updateAt(
    K key,
    V newValue, {
    bool notifyGlobal = false,
  }) {
    final newMap = Map<K, V>.of(value);

    newMap[key] = newValue;

    value = newMap;
  }

  /// Returns the underlying Map value.
  ///
  /// ## Example
  ///
  /// ```dart
  /// final rawMap = user.map;
  /// ```
  ///
  /// Prefer using `[]` for reactive reads when possible.
  Map<K, V> get map => value;
}
