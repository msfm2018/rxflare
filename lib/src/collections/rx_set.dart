import 'dart:collection';

import '../core/rx_state.dart';
import '../rx_router/rx_stack.dart';

/// A reactive implementation of [Set] backed by [RxState].
///
///
/// This class provides reactive tracking for set operations:
/// - Element presence tracking (`contains`)
/// - Size tracking (`length`)
/// - Mutations (`add`, `remove`)
///
///
/// All mutations follow an immutable update pattern:
/// a new Set instance is created before updating the state.
///
///
/// Example:
/// ```dart
/// final set = RxSet<int>({1, 2, 3});
///
/// set.add(4);       // triggers reactive update
/// set.contains(1);  // tracked read
/// ```
///
///
/// Key characteristics:
/// - Reactive read tracking via [RxStack]
/// - Immutable updates (Set.copy on mutation)
/// - Fine-grained dependency tracking support
class RxSet<T> extends RxState<Set<T>> {
  /// Creates a reactive set with an initial value.
  RxSet(super.initial);

  /// Adds [item] to the set.
  ///
  /// Returns `true` if the item was not already present and was added.
  ///
  /// Behavior:
  /// - If the item already exists, no update is triggered
  /// - If the item is new, a new Set instance is created
  /// - Reactive listeners are notified via state update
  bool add(T item) {
    final newSet = Set<T>.of(value);

    final added = newSet.add(item);

    if (added) {
      value = newSet;
    }

    return added;
  }

  /// Removes [item] from the set.
  ///
  /// Returns `true` if the item was present and removed.
  ///
  /// Behavior:
  /// - If the item does not exist, no update is triggered
  /// - If removed successfully, a new Set instance is created
  /// - Reactive listeners are notified via state update
  bool remove(T item) {
    final newSet = Set<T>.of(value);

    final removed = newSet.remove(item);

    if (removed) {
      value = newSet;
    }

    return removed;
  }

  /// Checks whether [item] exists in the set.
  ///
  /// This read operation is tracked reactively:
  /// any computed value or UI depending on this check
  /// will automatically update when the set changes.
  bool contains(T item) {
    RxStack.register(this);

    return value.contains(item);
  }

  /// The number of elements in the set.
  ///
  /// This getter is reactive and will trigger updates
  /// when the set changes.
  int get length {
    RxStack.register(this);

    return value.length;
  }

  /// Whether the set is empty.
  ///
  /// Reactive read: updates when the set changes.
  bool get isEmpty {
    RxStack.register(this);

    return value.isEmpty;
  }

  /// Whether the set is not empty.
  ///
  /// Reactive read: updates when the set changes.
  bool get isNotEmpty {
    RxStack.register(this);

    return value.isNotEmpty;
  }

  /// Returns an unmodifiable view of the underlying set.
  ///
  /// ⚠️ Important:
  /// - This view is read-only
  /// - Direct modification is not allowed
  /// - Use [add] / [remove] for updates
  ///
  /// Reactive tracking is applied on access.
  UnmodifiableSetView<T> get set {
    RxStack.register(this);

    return UnmodifiableSetView(value);
  }
}
