import '../core/rx_state.dart';
import '../rx_router/rx_stack.dart';

/// A reactive implementation of [Map] that extends [RxState].
///
///
/// This class provides fine-grained reactivity for map operations:
/// - Key-based read tracking (`map[key]`)
/// - Key-based update tracking (`map[key] = value`)
/// - Immutable updates (internally copies map on mutation)
///
///
/// Typical usage:
/// ```dart
/// final map = RxMap<String, int>({'a': 1});
///
/// print(map['a']); // tracked read
/// map['a'] = 2;    // triggers reactive update for key 'a'
/// ```
///
///
/// Key features:
/// - Reactive key access tracking
/// - Immutable update model (new Map created on mutation)
/// - Field-level notification support
class RxMap<K, V> extends RxState<Map<K, V>> {
  /// Creates a reactive map with an initial value.
  ///
  /// Optional parameters:
  /// - [id]: optional identifier for debugging or registry
  /// - [name]: optional human-readable name
  RxMap(
    super.initial, {
    super.id,
    super.name,
  });

  /// Gets the value associated with [key].
  ///
  /// This access is tracked reactively:
  /// - The current reactive context subscribes to this map
  /// - The specific [key] is registered for fine-grained updates
  ///
  /// Returns `null` if the key does not exist or value is null.
  V? operator [](K key) {
    RxStack.register(this);
    RxStack.registerField(this, key);

    return value[key];
  }

  /// Sets the [newValue] for the given [key].
  ///
  /// Behavior:
  /// - Compares old and new values using [deepEquals]
  /// - If unchanged, no update is triggered
  /// - Otherwise, a new Map instance is created (immutability guarantee)
  /// - Only listeners subscribed to this [key] are notified
  void operator []=(K key, V newValue) {
    final oldValue = value[key];

    if (deepEquals(oldValue, newValue)) return;

    final newMap = Map<K, V>.of(value);

    newMap[key] = newValue;

    value = newMap;

    notifyFieldListeners(key, false);
  }
}
