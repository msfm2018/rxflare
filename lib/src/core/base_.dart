import 'rx_state.dart';

/// ====================== Disposable Contract ======================
/// Base interface for objects that require manual cleanup.
///
/// This ensures consistent lifecycle management across reactive nodes.
abstract class Disposable {
  void dispose();
}

/// ====================== RxContext ======================
///
/// Internal dependency collection context used during reactive evaluation.
///
/// It tracks:
/// - state-level dependencies
/// - field-level dependencies
///
/// Used by RxComputed and reactive effects.
class RxContext {
  /// State dependencies collected during execution.
  final Set<RxState> states = {};

  /// Field-level dependencies grouped by RxState.
  final Map<RxState, Set<dynamic>> fields = {};
}

/// ====================== RxKey ======================
///
/// A unique key used for dependency injection and object lookup.
///
/// Combines:
/// - Type identity
/// - Optional name disambiguation
///
/// Example:
/// ```dart
/// RxKey(MyController, "home");
/// ```
class RxKey {
  final Type type;
  final String? name;

  const RxKey(this.type, this.name);

  @override
  bool operator ==(Object other) {
    return other is RxKey && other.type == type && other.name == name;
  }

  @override
  int get hashCode => Object.hash(type, name);

  @override
  String toString() => 'RxKey<$type>($name)';
}
