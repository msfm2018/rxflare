import 'package:flutter/foundation.dart';

import '../rx_router/rx_router.dart';
import '../utils/rx_debug.dart';

int _rxStateCounter = 0;

/// [RxState] is the core unit of reactive state.
///
/// It encapsulates a value of type [T] and provides:
/// - Automatic dependency tracking
/// - Fine-grained updates for Map and List fields
/// - Efficient change propagation with minimal updates
class RxState<T> {
  /// Unique identifier for debugging or tracking updates in [listenWithId].
  final dynamic id;

  /// A human-readable name, mainly used for logging and debugging output.
  final String? name;
  T _value;
  final List<void Function(dynamic)> _listeners = [];
  final List<void Function(dynamic)> _listenersWithId = []; //  with id
  final Map<dynamic, List<void Function(dynamic)>> _fieldListeners = {};

  /// Creates a reactive state.
  /// [id] is optional and defaults to a new [Object].
  /// [name] is optional and defaults to "RxState#`<index>`".
  RxState(this._value, {dynamic id, String? name})
      : id = id ?? Object(),
        name = name ?? "RxState#$_rxStateCounter" {
    _rxStateCounter++;
  }

  bool deepEquals(dynamic a, dynamic b) {
    if (a is Map && b is Map) return mapEquals(a, b);
    if (a is List && b is List) return listEquals(a, b);
    return a == b;
  }

  /// Gets the current value and automatically triggers dependency tracking in [RxStack].
  T get value {
    RxStack.register(this);
    return _value;
  }

  /// Internal setter that updates the value and notifies all global listeners.
  /// Returns true if the value actually changed.
  bool _setValue(T newValue) {
    
    if (!deepEquals(_value, newValue)) {
      _value = newValue;
      _notifyListeners(id);
      return true;
    }
    return false;
  }

  /// Internal setter used for field-level updates (Map/List).
  /// It updates the value and only notifies listeners bound to the specified field.
  /// Returns true if the value actually changed.
  bool _setFieldValue(T newValue, dynamic field) {
    if (!deepEquals(_value, newValue)) {
      _value = newValue;
      notifyField(field); // ✅ 正确
      return true;
    }
    return false;
  }

  /// Sets a new value. If the new value is different from the current one
  /// according to [deepEquals], it triggers global listeners.
  set value(T newValue) {
    _setValue(newValue);
  }

  /// Internal update used by computed or framework-level mechanisms.
  /// It updates the value and triggers global listeners if the value changes.
  @protected
  void internalUpdate(T newValue) {
    _setValue(newValue);
  }

  /// Gets a specific field or index from a collection.
  ///
  /// If [T] is a [Map], [field] represents the key.
  /// If [T] is a [List], [field] represents an integer index.
  /// Calling this method registers a field-level dependency, so only changes
  /// to that specific field will trigger updates.
  dynamic getItem(dynamic field) {
    RxStack.register(this);
    RxStack.registerField(this, field);

    if (_value is Map) {
      return (_value as Map)[field];
    } else if (_value is List && field is int) {
      final list = _value as List;
      if (field >= 0 && field < list.length) {
        return list[field];
      }
    }

    return null;
  }

  /// Updates the entire state or attempts a type-conversion update.
  ///
  /// Supports automatic conversion between `double` and `int`
  /// (with a precision loss warning when applicable).
  @protected
  void update(dynamic newValue) {
    final current = _value;

    // 1. Exact type match
    if (newValue is T) {
      _setValue(newValue);
      return;
    }

    // 2. Numeric compatibility (using num for simplicity)
    if (current is num && newValue is num) {
      dynamic converted;

      if (current is double) {
        converted = newValue.toDouble();
      } else if (current is int) {
        if (newValue is double) {
          RxDebug.log(" RxState(${name ?? id}): double → int precision may be lost: $newValue");
        }
        converted = newValue.toInt();
      }

      _setValue(converted as T);
      return;
    }

    // 3. Type mismatch
    RxDebug.log(
      '[Type Error] RxState(${name ?? id}): '
      'Cannot assign ${newValue.runtimeType} to ${current.runtimeType}',
    );
  }

  /// Updates a specific key in a Map or an index in a List.
  ///
  /// [field]: Map key or List index.
  /// [newValue]: New value to assign.
  void updateField<K extends Object>(K field, Object? newValue) {
    final current = _value;
    if (current == null) {
      RxDebug.log("RxState(${name ?? id}) is null, cannot update field $field");
      return;
    }

    if (current is Map && current.containsKey(field)) {
      late final Map newMap;
      final oldFieldValue = current[field];
      if (deepEquals(oldFieldValue, newValue)) return;

      if (current is Map<String, Object>) {
        final m = Map<String, Object>.of(current);
        m[field as String] = newValue!;
        newMap = m;
      } else if (current is Map<String, dynamic>) {
        final m = Map<String, dynamic>.of(current);
        m[field as String] = newValue!;
        newMap = m;
      } else {
        // Fallback for generic Map
        final m = Map.from(current);
        m[field] = newValue;
        newMap = m;
      }
      _setFieldValue(newMap as T, field);

      return;
    }

    if (current is List && field is int) {
      if (field < 0 || field >= current.length) {
        RxDebug.log(" List index out of range: $field");
        return;
      }
      final oldItem = current[field];
      if (deepEquals(oldItem, newValue)) return;

      final newList = (current as List).toList();
      newList[field] = newValue;
      _setFieldValue(newList as T, field);

      return;
    }

    // Fallback: full replacement
    if (newValue is T) {
      _setValue(newValue); // ✅ 不是 field
    }
  }

  /// Adds a field-level listener.
  ///
  /// Supports any key type such as int, String, or Object.
  /// These listeners are triggered only when the specified field changes.
  @protected
  void addFieldListener(dynamic field, void Function(dynamic) listener) {
    // _fieldListeners.putIfAbsent(field, () => []).add(listener);
    final list = _fieldListeners.putIfAbsent(field, () => []);
    if (!list.contains(listener)) {
      list.add(listener);
    }
  }

  /// Removes a field-level listener.
  ///
  /// If the listener list becomes empty, the field entry will be removed
  /// to reduce memory usage.
  @protected
  void removeFieldListener(dynamic field, void Function(dynamic) listener) {
    final fieldListeners = _fieldListeners[field];
    if (fieldListeners != null) {
      fieldListeners.remove(listener);
      // Clean up empty listener lists to reduce memory usage
      if (fieldListeners.isEmpty) {
        _fieldListeners.remove(field);
      }
    }
  }

  /// Notifies all listeners registered for a specific field.
  ///
  /// It extracts the current field value from either a Map or List
  /// and dispatches it to all registered field listeners.
  @protected
  void notifyField(dynamic field) {
    final ls = _fieldListeners[field]?.toList();

    if (ls != null && ls.isNotEmpty) {
      dynamic fieldValue;

      if (_value is Map) {
        fieldValue = (_value as Map)[field];
      } else if (_value is List && field is int) {
        final list = _value as List;
        if (field >= 0 && field < list.length) {
          fieldValue = list[field];
        }
      }

      for (final l in ls) {
        l(fieldValue);
      }
    }
  }

  /// Adds a global listener.
  ///
  /// The listener will be triggered whenever the entire state changes.
  @protected
  void addListener(void Function(dynamic) listener) {
    if (!_listeners.contains(listener)) {
      _listeners.add(listener);
    }
  }

  /// Adds a listener that also receives the state id.
  ///
  /// Useful for distinguishing the origin of updates in complex systems.
  @protected
  void addListenerWithId(void Function(dynamic) listener) {
    if (!_listenersWithId.contains(listener)) {
      _listenersWithId.add(listener);
    }
  }

  /// Binds a listener to the state.
  ///
  /// [onUpdate] is called whenever the value changes.
  /// Returns a function that cancels the binding.
  void Function() bind(void Function(T value) onUpdate) {
    // Wrapper to match internal void Function(dynamic) signature
    void wrapper(dynamic _) => onUpdate(_value);

    _listeners.add(wrapper);

    // In navigation Delegate scenarios, we usually do not trigger an
    // immediate notification here because the first build already
    // invokes rendering.
    //
    // If immediate execution is needed, uncomment:
    // onUpdate(_value);

    bool disposed = false;
    return () {
      if (!disposed) {
        _listeners.remove(wrapper);
        disposed = true;
      }
    };
  }

  /// Listens to value changes and immediately emits the current value.
  ///
  /// Returns a function that cancels the subscription.
  void Function() listen(void Function(T value) onData) {
    void wrapper(dynamic _) => onData(_value);
    _listeners.add(wrapper);
    // Immediately emit current value once
    onData(_value);
    // 返回取消监听的闭包（优化：增加空检查）
    bool disposed = false;
    return () {
      if (!disposed) {
        _listeners.remove(wrapper);
        disposed = true;
      }
    };
  }

  // count.listenWithId((v, id) {
  //   print("value: $v, from: $id");
  // });
  /// Listens to value changes and provides both value and state id.
  ///
  /// Useful when you need to know the origin of updates in complex systems.
  void Function() listenWithId(void Function(T value, dynamic id) onData) {
    void wrapper(dynamic id) => onData(_value, id);

    _listenersWithId.add(wrapper);

    // Immediately emit current state once
    onData(_value, id);

    bool disposed = false;
    return () {
      if (!disposed) {
        _listenersWithId.remove(wrapper);
        disposed = true;
      }
    };
  }

  /// Conditional listener.
  ///
  /// Only emits when the provided test function returns true.
  void Function() listenWhere(bool Function(dynamic item) test, void Function(dynamic item) onData) {
    void wrapper(dynamic _) {
      if (_value is Map) {
        if (test(_value)) {
          onData(_value);
        } else {
          onData(null);
        }
      } else {
        onData(_value);
      }
    }

    _listeners.add(wrapper);

    // Initial trigger
    wrapper(_value);

    bool disposed = false;
    return () {
      if (!disposed) {
        _listeners.remove(wrapper);
        disposed = true;
      }
    };
  }

  /// Listens to a specific key in a Map or index in a List.
  ///
  /// Only triggers when the targeted field changes.
  void Function() listenByKey(dynamic key, void Function(dynamic value) onData) {
    void wrapper(dynamic value) => onData(value);

    addFieldListener(key, wrapper);

    // Initial value
    dynamic fieldValue;

    if (_value is Map) {
      fieldValue = (_value as Map)[key];
    } else if (_value is List && key is int) {
      final list = _value as List;
      if (key >= 0 && key < list.length) {
        fieldValue = list[key];
      }
    }

    onData(fieldValue);

    bool cancelled = false;
    return () {
      if (!cancelled) {
        removeFieldListener(key, wrapper);
        cancelled = true;
      }
    };
  }

  /// Removes a global listener.
  @protected
  void removeListener(void Function(dynamic) listener) {
    _listeners.remove(listener);
  }

  /// Notifies all listeners.
  void _notifyListeners(dynamic id) {
    // Iterate backwards to safely support removal during iteration
    for (var i = _listeners.length - 1; i >= 0; i--) {
      _listeners[i](id);
    }
    // Notify listeners that also receive the id
    for (var i = _listenersWithId.length - 1; i >= 0; i--) {
      _listenersWithId[i](id);
    }
  }

  /// Disposes the state and clears all listeners.
  void dispose() {
    _listeners.clear();
    _fieldListeners.clear();
    RxDebug.log(" RxState(${name ?? id}) has been disposed and cleared");
  }

  /// Manually triggers a refresh.
  void refresh() {
    _notifyListeners(id);
  }
}
