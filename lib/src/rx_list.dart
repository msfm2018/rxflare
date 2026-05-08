import 'rx_state.dart';

/// A reactive List state container.
///
/// [RxList] is a specialized reactive state class for managing `List<T>` data.
///
/// Compared to using `RxState<List<T>>` directly, this class provides:
///
/// - Native List-like syntax (`[]`, `[]=`)
/// - Immutable update behavior
/// - Automatic reactive notifications
/// - Safer list operations
/// - Better readability for reactive collections
///
/// ## Example
///
/// ```dart
/// final todos = RxList<String>([
///   "Learn Flutter",
///   "Build app",
/// ]);
///
/// todos.add("Deploy app");
///
/// print(todos[0]); // Learn Flutter
/// ```
///
/// ## Reactive Usage
///
/// ```dart
/// Rx(() {
///   return Text(todos[0]);
/// });
/// ```
///
/// ## Immutable Updates
///
/// Every mutation creates a new List instance internally:
///
/// ```dart
/// final newList = List<T>.of(value);
/// ```
///
/// This ensures reactive listeners and Flutter widgets
/// can properly detect state changes.
class RxList<T> extends RxState<List<T>> {
  /// Creates a reactive list state.
  ///
  /// The [initial] parameter defines the initial list value.
  ///
  /// ## Example
  ///
  /// ```dart
  /// final numbers = RxList<int>([1, 2, 3]);
  /// ```
  RxList(super.initial);

  /// Returns the item at the specified [index].
  ///
  /// Behaves like a normal Dart List getter.
  ///
  /// ## Example
  ///
  /// ```dart
  /// final item = todos[0];
  /// ```
  T operator [](int index) => value[index];

  /// Updates the item at the specified [index].
  ///
  /// This operation performs an immutable update
  /// and automatically triggers reactive notifications.
  ///
  /// ## Example
  ///
  /// ```dart
  /// todos[0] = "Updated Todo";
  /// ```
  ///
  /// Equivalent to:
  ///
  /// ```dart
  /// todos.updateAt(0, "Updated Todo");
  /// ```
  void operator []=(int index, T newValue) {
    updateAt(index, newValue);
  }

  /// Updates the item at the specified [index].
  ///
  /// Internally creates a new immutable List instance
  /// to ensure proper reactive updates.
  ///
  /// ## Example
  ///
  /// ```dart
  /// todos.updateAt(1, "New Value");
  /// ```
  ///
  /// If the index is out of bounds,
  /// a warning message will be printed.
  ///
  /// The optional [notifyGlobal] parameter is reserved
  /// for future fine-grained/global notification strategies.
  void updateAt(
    int index,
    T newValue, {
    bool notifyGlobal = false,
  }) {
    if (index < 0 || index >= value.length) {
      print("⚠️ RxList index out of range: $index");
      return;
    }

    final newList = List<T>.of(value);

    newList[index] = newValue;

    value = newList;
  }

  /// Adds a new [item] to the end of the list.
  ///
  /// This operation creates a new immutable List instance
  /// and automatically triggers reactive notifications.
  ///
  /// ## Example
  ///
  /// ```dart
  /// todos.add("New Task");
  /// ```
  void add(T item) {
    final newList = List<T>.of(value)..add(item);

    value = newList;
  }

  /// Removes the item at the specified [index].
  ///
  /// This operation creates a new immutable List instance
  /// and automatically triggers reactive notifications.
  ///
  /// ## Example
  ///
  /// ```dart
  /// todos.removeAt(0);
  /// ```
  ///
  /// Throws a [RangeError] if the index is invalid,
  /// matching native Dart List behavior.
  void removeAt(int index) {
    final newList = List<T>.of(value)..removeAt(index);

    value = newList;
  }

  /// Returns the underlying raw List value.
  ///
  /// ## Example
  ///
  /// ```dart
  /// final rawList = todos.list;
  /// ```
  ///
  /// Prefer using `[]` for reactive reads when possible.
  List<T> get list => value;
}
