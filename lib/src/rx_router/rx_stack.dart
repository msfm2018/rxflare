import '../core/base_.dart';
import '../core/rx_state.dart';
import '../utils/rx_debug.dart';

/// **RxStack** is the internal dependency tracking stack used by RxFlare.
///
/// It manages nested contexts during reactive computations and widget building.
/// Using a push/pop mechanism, it enables accurate automatic dependency tracking
/// for both state-level and field-level dependencies.
class RxStack {
  /// Internal stack that holds active [RxContext]s.
  static final List<RxContext> _stack = [];

  /// Returns the current top-most context, or `null` if the stack is empty.
  static RxContext? get current => _stack.isNotEmpty ? _stack.last : null;

  /// Pushes a new context onto the stack.
  ///
  /// Called at the beginning of a reactive builder execution.
  static void push(RxContext ctx) {
    _stack.add(ctx);
  }

  /// Pops the top context from the stack.
  ///
  /// Called after a reactive builder finishes execution.
  static void pop() {
    if (_stack.isNotEmpty) {
      _stack.removeLast();
    }
  }

  /// Registers a state-level dependency.
  ///
  /// The [state] will be added to the current context's state dependencies.
  static void register(RxState state) {
    final ctx = current;
    if (ctx != null) {
      // 仅在添加成功时打印日志
      if (ctx.states.add(state)) {
        RxDebug.log("  Bound State: ${state.name ?? state.id}");
      }
    }
  }

  /// Registers a field-level dependency.
  ///
  /// The combination of [state] and [field] (key or index) will be recorded
  /// in the current context for precise updates.
  static void registerField(RxState state, dynamic field) {
    final ctx = current;
    if (ctx != null) {
      final fields = ctx.fields.putIfAbsent(state, () => <dynamic>{});
      if (fields.add(field)) {
        RxDebug.log("  Bound Field: ${state.name ?? state.id}[$field]");
      }
    }
  }
}
