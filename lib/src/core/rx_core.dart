import '../collections/rx_list.dart';
import '../collections/rx_map.dart';
import '../collections/rx_set.dart';
import 'rx_state.dart';

/// ==============================
/// Universal `.obs` Extension
/// ==============================

/// Converts any value into an `RxState<T>`.
///
/// This is the primary entry point for creating reactive state.
///
/// Example:
/// ```dart
/// final count = 0.obs;
/// final name = "Tom".obs;
/// final list = [1, 2, 3].obs;
/// ```
extension RxAnyExtension<T> on T {
  /// 将当前对象包装成 `RxState<T>`
  RxState<T> get obs => RxState<T>(this);
}

/// Type aliases for `RxState`.
///
/// These aliases improve readability and allow developers to
/// use different semantic meanings depending on the context.
///
/// Example:
/// ```dart
/// RxValue<int> count = 0.obs;
/// RxStore<User> userStore = user.obs;
/// ```
typedef RxValue<T> = RxState<T>;
typedef RxStore<T> = RxState<T>;
typedef RxNotifier<T> = RxState<T>;

/// ==============================
/// List Enhancements for RxState
/// ==============================

/// Provides additional utility methods for `RxState<List<T>>`.
///
/// These helpers allow you to mutate the list while automatically
/// triggering UI updates.
///
/// Example:
/// ```dart
/// final items = <int>[].obs;
/// items.add(1);
/// items.remove(1);
/// ```
extension RxListToState<T> on RxState<List<T>> {
  /// Returns whether the list contains the given [element].
  bool contains(T element) => value.contains(element);

  /// Adds an [element] to the list and triggers a refresh.
  void add(T element) {
    value.add(element);
    refresh(); // 自动触发 UI 更新
  }

  /// Removes an [element] from the list and triggers a refresh.
  void remove(T element) {
    value.remove(element);
    refresh();
  }

  /// Whether the list is empty.
  bool get isEmpty => value.isEmpty;

  /// Whether the list is not empty.
  bool get isNotEmpty => value.isNotEmpty;

  /// The number of elements in the list.
  int get length => value.length;
}

/// ==============================
/// Strongly Typed Collection Extensions
/// ==============================

/// Converts a `Map<K, V>` into an `RxMap<K, V>`.
///
/// Example:
/// ```dart
/// final user = {"name": "Tom"}.obsMap;
/// ```
extension RxMapExtension<K, V> on Map<K, V> {
  RxMap<K, V> get obsMap => RxMap<K, V>(this);
}

/// Converts a `List<T>` into an `RxList<T>`.
///
/// Example:
/// ```dart
/// final todos = ["A", "B"].obsList;
/// ```
extension RxListExtension<T> on List<T> {
  RxList<T> get obsList => RxList<T>(this);
}

/// Converts a `Set<T>` into an `RxSet<T>`.
///
/// Example:
/// ```dart
/// final tags = {"flutter", "dart"}.obsSet;
/// ```
extension RxSetExtension<T> on Set<T> {
  RxSet<T> get obsSet => RxSet<T>(this);
}

/// ==============================
/// JSON-friendly Extensions
/// ==============================

/// Specialized extension for JSON-like maps.
///
/// This is commonly used when working with API responses.
///
/// Example:
/// ```dart
/// final json = {"id": 1, "name": "Tom"}.obsMapD;
/// ```
extension RxMapDynamicExtension on Map<String, dynamic> {
  /// Converts a `Map<String, dynamic>` into an `RxMap`.
  RxMap<String, dynamic> get obsMapD => RxMap<String, dynamic>(this);
}

/// Specialized extension for list of JSON objects.
///
/// Useful for API responses returning arrays of objects.
///
/// Example:
/// ```dart
/// final list = [
///   {"id": 1},
///   {"id": 2}
/// ].obsListMap;
/// ```
extension RxListMapExtension on List<Map<String, dynamic>> {
  /// Converts a `List<Map<String, dynamic>>` into an `RxList`.
  RxList<Map<String, dynamic>> get obsListMap => RxList<Map<String, dynamic>>(this);
}
