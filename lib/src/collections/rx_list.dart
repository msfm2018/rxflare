import '../core/rx_state.dart';
import '../rx_router/rx_stack.dart';

/// A reactive list that extends [RxState] and provides fine-grained
/// reactivity on both list-level and index-level access.
///
///
/// This class allows tracking:
/// - Whole list changes (add/remove/replace)
/// - Individual index access tracking
///
/// It is typically used in reactive UI systems where rebuilds
/// should be minimized and only triggered for specific dependencies.
class RxList<T> extends RxState<List<T>> {
  /// Creates a reactive list with an initial value.
  RxList(super.initial);

  /// Gets the element at [index].
  ///
  /// This access is tracked by the reactive system, meaning:
  /// - The current Rx dependency will subscribe to this list
  /// - The specific index is also registered for fine-grained updates
  ///
  /// Throws [RangeError] if index is out of bounds.
  T operator [](int index) {
    RxStack.register(this);
    RxStack.registerField(this, index);

    return value[index];
  }

  /// Updates the element at [index] with [newValue].
  ///
  /// If the new value is equal to the old value (via [deepEquals]),
  /// no update or notification will be triggered.
  ///
  /// After updating, only listeners subscribed to this index
  /// will be notified via [notifyFieldListeners].
  void operator []=(int index, T newValue) {
    final oldValue = value[index];

    if (deepEquals(oldValue, newValue)) {
      return;
    }

    final newList = List<T>.of(value);

    newList[index] = newValue;

    value = newList;

    notifyFieldListeners(index, false);
  }

  /// Updates the value at a specific index.
  ///
  /// This is a convenience wrapper around `[]=` for semantic clarity.
  ///
  /// If [notifyGlobal] is true, global listeners may also be notified
  /// depending on implementation in [RxState].
  void updateAt(
    int index,
    T newValue, {
    bool notifyGlobal = false,
  }) {
    this[index] = newValue;
  }

  /// Adds an [item] to the end of the list.
  ///
  /// This creates a new list instance to maintain immutability guarantees
  /// required by the reactive system.
  void add(T item) {
    final newList = List<T>.of(value)..add(item);

    value = newList;
  }

  /// Removes the element at [index].
  ///
  /// A new list is created to ensure proper reactive updates.
  ///
  /// Throws [RangeError] if index is out of bounds.
  void removeAt(int index) {
    final newList = List<T>.of(value)..removeAt(index);

    value = newList;
  }

  /// Returns the underlying raw list.
  ///
  /// ⚠️ Note:
  /// Modifying this list directly will NOT trigger reactivity.
  /// Prefer using provided methods like [add], [removeAt], or `[]=` instead.
  List<T> get list => value;

  /// Returns the length of the list.
  ///
  /// Accessing this property is tracked reactively, meaning
  /// UI or computed values depending on length will update automatically.
  int get length {
    RxStack.register(this);
    return value.length;
  }
}
