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
  /// will be notified via [notifyField].
  void operator []=(int index, T newValue) {
    final oldValue = value[index];

    if (deepEquals(oldValue, newValue)) {
      return;
    }

    final newList = List<T>.of(value);

    newList[index] = newValue;

    value = newList;

    notifyField(index);
  }

  /// Returns a new list containing all elements that satisfy the [test] predicate.
  ///
  /// This method is **reactive** — it registers the current Rx context,
  /// so any changes to the original list will trigger rebuilds in UI.
  List<T> where(bool Function(T element) test) {
    RxStack.register(this);
    return value.where(test).toList();
  }

  /// Returns a new list containing all elements that satisfy the [test] predicate.
  ///
  /// Same as [where], but more semantic for filtering (recommended for search).
  List<T> filter(bool Function(T element) test) {
    RxStack.register(this);
    return value.where(test).toList();
  }

  /// Returns the first element or null if not found.
  ///
  /// Alias of [firstWhereOrNull] for semantic clarity.
  T? maybeFirst(bool Function(T element) test) {
    return firstWhereOrNull(test);
  }

  /// Finds the first element that matches [test].
  ///
  /// Alias of [firstWhere] for more readable API.
  T find(bool Function(T element) test) {
    return firstWhere(test);
  }

  /// Finds the index of the first matching element.
  ///
  /// Returns -1 if not found.
  int findIndex(bool Function(T element) test) {
    RxStack.register(this);
    return value.indexWhere(test);
  }

  /// Updates all elements that satisfy [test] using [update].
  ///
  /// Only triggers update if at least one element changes.
  void updateWhere(bool Function(T element) test, T Function(T element) update) {
    bool changed = false;
    final newList = List<T>.of(value);

    for (int i = 0; i < newList.length; i++) {
      final item = newList[i];

      if (test(item)) {
        final newItem = update(item);

        if (!deepEquals(item, newItem)) {
          newList[i] = newItem;
          changed = true;

          notifyField(i);
        }
      }
    }

    if (changed) {
      value = newList;
    }
  }

  /// Replaces all elements that match [test] with [newValue].
  void replaceWhere(bool Function(T element) test, T newValue) {
    bool changed = false;
    final newList = List<T>.of(value);

    for (int i = 0; i < newList.length; i++) {
      if (test(newList[i])) {
        if (!deepEquals(newList[i], newValue)) {
          newList[i] = newValue;
          changed = true;

          notifyField(i);
        }
      }
    }

    if (changed) {
      value = newList;
    }
  }

  /// Safely gets element at [index].
  ///
  /// Returns null if index is out of bounds.
  T? safeIndex(int index) {
    RxStack.register(this);

    if (index < 0 || index >= value.length) return null;

    RxStack.registerField(this, index);
    return value[index];
  }

  /// Returns the first element that satisfies [test].
  ///
  /// This access is tracked reactively so UI can rebuild
  /// when underlying list changes.
  T firstWhere(bool Function(T element) test, {T Function()? orElse}) {
    RxStack.register(this);

    final index = value.indexWhere(test);

    if (index != -1) {
      return value[index];
    }

    if (orElse != null) return orElse();

    throw StateError('No element found');
  }

  T? firstWhereOrNull(bool Function(T) test) {
    RxStack.register(this);

    for (final item in value) {
      if (test(item)) return item;
    }
    return null;
  }

  T singleWhere(bool Function(T) test) {
    RxStack.register(this);
    return value.singleWhere(test);
  }

  int indexWhere(bool Function(T) test) {
    RxStack.register(this);
    return value.indexWhere(test);
  }

  bool contains(T item) {
    RxStack.register(this);
    return value.contains(item);
  }

  /// Updates the value at a specific index.
  ///
  /// This is a convenience wrapper around `[]=` for semantic clarity.
  ///
  /// If [notifyGlobal] is true, global listeners may also be notified
  /// depending on implementation in [RxState].
  void updateAt(int index, T newValue, {bool notifyGlobal = false}) {
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

  /// Adds multiple items to the list.
  ///
  /// This creates a new list instance to ensure reactivity.
  void addAll(Iterable<T> items) {
    value = List<T>.of(value)..addAll(items);
  }

  /// Inserts an item at the given index.
  ///
  /// A new list instance is created to trigger reactive updates.
  void insert(int index, T item) {
    value = List<T>.of(value)..insert(index, item);
  }

  /// Removes the first occurrence of the given item.
  ///
  /// Returns `true` if the item was removed, otherwise `false`.
  /// A new list instance is assigned if removal succeeds.
  bool remove(T item) {
    final newList = List<T>.of(value);
    if (newList.remove(item)) {
      value = newList;
      return true;
    }
    return false;
  }

  /// Maps each element using the provided function.
  ///
  /// This method also registers the current Rx context
  /// to ensure proper reactive tracking.
  ///
  /// Useful when transforming reactive lists without losing reactivity.
  List<R> map<R>(R Function(T) toElement) {
    RxStack.register(this); // 保持响应式
    return value.map(toElement).toList();
  }

  /// Removes all elements that satisfy the given condition.
  ///
  /// A new list instance is created to notify listeners.
  void removeWhere(bool Function(T) test) {
    value = List<T>.of(value)..removeWhere(test);
  }

  /// Clears all elements from the list.
  ///
  /// Resets the list to an empty state and notifies listeners.
  void clear() {
    value = <T>[];
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
  ///  Note:
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
