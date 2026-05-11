import '../core/rx_state.dart';

/// A reactive Set state container.
///
/// [RxSet] is a specialized reactive state class for managing `Set<T>` data.
///
/// Compared to using `RxState<Set<T>>` directly, this class provides:
///
/// - Immutable Set updates
/// - Automatic reactive notifications
/// - Native Set-like APIs
/// - Safer mutation handling
/// - Cleaner reactive collection management
///
/// ## Example
///
/// ```dart
/// final tags = RxSet<String>({
///   "flutter",
///   "dart",
/// });
///
/// tags.add("rxflare");
///
/// print(tags.contains("flutter")); // true
/// ```
///
/// ## Reactive Usage
///
/// ```dart
/// Rx(() {
///   return Text("Tags: ${tags.length}");
/// });
/// ```
///
/// ## Immutable Updates
///
/// Every mutation creates a new Set instance internally:
///
/// ```dart
/// final newSet = Set<T>.of(value);
/// ```
///
/// This ensures Flutter widgets and reactive systems
/// can correctly detect changes and trigger updates.
///
/// ## Notes
///
/// [RxSet] preserves the behavior of native Dart Set,
/// including uniqueness guarantees.
///
/// Duplicate items will not be added.
class RxSet<T> extends RxState<Set<T>> {
  /// Creates a reactive Set state.
  ///
  /// The [initial] parameter defines the initial Set value.
  ///
  /// ## Example
  ///
  /// ```dart
  /// final selectedIds = RxSet<int>({1, 2, 3});
  /// ```
  RxSet(super.initial);

  /// Adds an [item] to the Set.
  ///
  /// Returns `true` if the item was added successfully.
  ///
  /// Returns `false` if the item already exists.
  ///
  /// This operation performs an immutable update
  /// and automatically triggers reactive notifications.
  ///
  /// ## Example
  ///
  /// ```dart
  /// tags.add("dart");
  /// ```
  bool add(T item) {
    final newSet = Set<T>.of(value);

    final added = newSet.add(item);

    if (added) {
      value = newSet;
    }

    return added;
  }

  /// Removes an [item] from the Set.
  ///
  /// Returns `true` if the item existed and was removed.
  ///
  /// Returns `false` if the item was not found.
  ///
  /// This operation performs an immutable update
  /// and automatically triggers reactive notifications.
  ///
  /// ## Example
  ///
  /// ```dart
  /// tags.remove("flutter");
  /// ```
  bool remove(T item) {
    final newSet = Set<T>.of(value);

    final removed = newSet.remove(item);

    if (removed) {
      value = newSet;
    }

    return removed;
  }

  /// Returns whether the Set contains the specified [item].
  ///
  /// ## Example
  ///
  /// ```dart
  /// final exists = tags.contains("dart");
  /// ```
  bool contains(T item) => value.contains(item);

  /// Returns the underlying raw Set value.
  ///
  /// ## Example
  ///
  /// ```dart
  /// final rawSet = tags.set;
  /// ```
  Set<T> get set => value;

  /// Returns the total number of items in the Set.
  ///
  /// ## Example
  ///
  /// ```dart
  /// print(tags.length);
  /// ```
  int get length => value.length;
}
