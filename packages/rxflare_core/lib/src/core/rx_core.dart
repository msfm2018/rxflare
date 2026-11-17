import '../collections/rx_list.dart';
import '../collections/rx_map.dart';
import '../collections/rx_set.dart';
import 'rx_state.dart';

/// ==============================
/// Universal `.rx` Extension
/// ==============================

/// Converts any value into an [RxState].
///
/// This is the primary entry point for creating reactive state.
/// Use `.rx` for new code. The legacy `.rx` getter remains available
/// as a deprecated compatibility alias.
///
/// Example:
/// ```dart
/// final count = 0.rx;
/// final name = 'Tom'.rx;
/// final values = <int>[1, 2, 3].rx;
/// ```
extension RxAnyExtension<T> on T {
  /// Converts this value into an [RxState].
  RxState<T> get rx => RxState<T>(this);

  /// Legacy alias for [rx]. Prefer `.rx` in new code.
  @Deprecated('Use .rx instead.')
  RxState<T> get obs => RxState<T>(this);
}

/// ==============================
/// Boolean Enhancements for RxState
/// ==============================

/// Provides additional utility methods for [RxState<bool>].
///
/// Example:
/// ```dart
/// final isExpanded = false.rx;
/// isExpanded.toggle(); // value becomes true
/// ```
extension RxBoolExtension on RxState<bool> {
  /// Toggles the boolean value and triggers UI update.
  ///
  /// Returns the new boolean value.
  bool toggle() {
    value = !value;
    return value;
  }
}

/// Type aliases for [RxState].
///
/// These aliases improve readability and allow developers to use
/// different semantic meanings depending on the context.
///
/// Example:
/// ```dart
/// RxValue<int> count = 0.rx;
/// RxStore<User> userStore = user.rx;
/// ```
typedef RxValue<T> = RxState<T>;
typedef RxStore<T> = RxState<T>;
typedef RxNotifier<T> = RxState<T>;

/// ==============================
/// List Enhancements for RxState
/// ==============================

/// Provides additional utility methods for [RxState<List<T>>].
///
/// A List wrapped with `.rx` remains an [RxState<List<T>>]. For
/// index-level collection reactivity, use `.rxList` instead.
extension RxListToState<T> on RxState<List<T>> {
  /// Returns whether the list contains [element].
  bool contains(T element) => value.contains(element);

  /// Adds [element] and triggers a refresh.
  void add(T element) {
    value.add(element);
    refresh();
  }

  /// Removes [element] and triggers a refresh.
  void remove(T element) {
    value.remove(element);
    refresh();
  }

  /// Whether the list is empty.
  bool get isEmpty => value.isEmpty;

  /// Whether the list is not empty.
  bool get isNotEmpty => value.isNotEmpty;

  /// Number of elements in the list.
  int get length => value.length;
}

/// ==============================
/// Strongly Typed Collection Extensions
/// ==============================

/// Converts a [Map] into an [RxMap].
///
/// Example:
/// ```dart
/// final user = <String, Object?>{'name': 'Tom'}.rxMap;
/// ```
extension RxMapExtension<K, V> on Map<K, V> {
  /// Converts this Map into an [RxMap].
  RxMap<K, V> get rxMap => RxMap<K, V>(this);

  /// Legacy alias for [rxMap]. Prefer `.rxMap` in new code.
  @Deprecated('Use .rxMap instead.')
  RxMap<K, V> get obsMap => RxMap<K, V>(this);
}

/// Converts a [List] into an [RxList].
///
/// Example:
/// ```dart
/// final todos = <String>['A', 'B'].rxList;
/// ```
extension RxListExtension<T> on List<T> {
  /// Converts this List into an [RxList].
  RxList<T> get rxList => RxList<T>(this);

  /// Legacy alias for [rxList]. Prefer `.rxList` in new code.
  @Deprecated('Use .rxList instead.')
  RxList<T> get obsList => RxList<T>(this);
}

/// Converts a [Set] into an [RxSet].
///
/// Example:
/// ```dart
/// final tags = <String>{'flutter', 'dart'}.rxSet;
/// ```
extension RxSetExtension<T> on Set<T> {
  /// Converts this Set into an [RxSet].
  RxSet<T> get rxSet => RxSet<T>(this);

  /// Legacy alias for [rxSet]. Prefer `.rxSet` in new code.
  @Deprecated('Use .rxSet instead.')
  RxSet<T> get obsSet => RxSet<T>(this);
}

/// ==============================
/// JSON-friendly Extensions
/// ==============================

/// Specialized extensions for JSON-like Maps.
extension RxMapDynamicExtension on Map<String, dynamic> {
  /// Converts this JSON Map into an [RxMap].
  RxMap<String, dynamic> get rxMapD => RxMap<String, dynamic>(this);

  /// Legacy alias for [rxMapD]. Prefer `.rxMapD` in new code.
  @Deprecated('Use .rxMapD instead.')
  RxMap<String, dynamic> get obsMapD => RxMap<String, dynamic>(this);
}

/// Specialized extension for a List of JSON objects.
extension RxListMapExtension on List<Map<String, dynamic>> {
  /// Converts this List into an [RxList].
  RxList<Map<String, dynamic>> get rxListMap =>
      RxList<Map<String, dynamic>>(this);

  /// Legacy alias for [rxListMap]. Prefer `.rxListMap` in new code.
  @Deprecated('Use .rxListMap instead.')
  RxList<Map<String, dynamic>> get obsListMap =>
      RxList<Map<String, dynamic>>(this);
}
