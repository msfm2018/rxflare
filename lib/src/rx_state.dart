import 'package:flutter/foundation.dart';
import 'rx_stack.dart';
import 'rx_debug.dart';

int _rxStateCounter = 0;

/// [RxState] 是响应式状态的基础单元。
///
/// 它封装了一个类型为 [T] 的值，并提供了自动依赖追踪和字段级（Map/List）更新机制
class RxState<T> {
  /// 唯一标识符，用于调试或在 [listenWithId] 中识别来源。
  final dynamic id;

  /// 友好的名称，主要用于日志打印。
  final String? name;
  T _value;
  final List<void Function(dynamic)> _listeners = [];
  final List<void Function(dynamic)> _listenersWithId = []; // 👈 带 id
  final Map<dynamic, List<void Function(dynamic)>> _fieldListeners = {};

  /// 创建一个响应式状态。
  /// [id] 可选，默认为一个新的 [Object]。
  /// [name] 可选，默认为 "RxState#序号"。
  RxState(this._value, {dynamic id, String? name})
      : id = id ?? Object(),
        name = name ?? "RxState#$_rxStateCounter" {
    _rxStateCounter++;
  }

  bool _deepEquals(dynamic a, dynamic b) {
    if (a is Map && b is Map) return mapEquals(a, b); // 需要 import 'package:flutter/foundation.dart';
    if (a is List && b is List) return listEquals(a, b);
    return a == b;
  }

  /// 获取当前值，并自动触发 [RxStack] 的依赖收集。
  T get value {
    RxStack.register(this);
    return _value;
  }

  /// 设置新值。如果新旧值通过 [_deepEquals] 判断不一致，则触发全局监听器。
  set value(T newValue) {
    if (!_deepEquals(_value, newValue)) {
      _value = newValue;
      _notifyListeners(id);
    }
  }

  /// 获取集合中的特定字段或索引。
  ///
  /// 如果 [T] 是 [Map]，[field] 为 Key。
  /// 如果 [T] 是 [List]，[field] 为 [int] 类型的索引。
  /// 调用此方法会注册字段级依赖，只有当该特定字段改变时才会触发监听。
  dynamic getItem(dynamic field) {
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

  // 内部监听接口：供 RxComputed 等组件绑定依赖
  void addInternalListener(void Function(dynamic) listener) {
    if (!_listeners.contains(listener)) {
      _listeners.add(listener);
    }
  }

  // 2. 这里的 internalUpdate 就是 RxComputed 会调用的“后门”
  void internalUpdate(T newValue) {
    if (!_deepEquals(_value, newValue)) {
      _value = newValue;
      _notifyListeners(id);
    }
  }

  /// 更新整个状态或尝试类型转换更新。
  ///
  /// 支持 double 和 int 之间的自动转换（带精度丢失警告）。
  void update(dynamic newValue) {
    final current = _value;

    // 1. 完全匹配类型
    if (newValue is T) {
      if (current != newValue) {
        value = newValue;
      }
      return;
    }

    // 2. 数值类型兼容（推荐用 current 判断）
    if (current is double && newValue is int) {
      final converted = newValue.toDouble();
      if (current != converted) {
        value = converted as T;
      }
      return;
    }

    if (current is int && newValue is double) {
      RxDebug.log("⚠️ RxState(${name ?? id}): double → int 可能丢失精度: $newValue");

      final converted = newValue.toInt();

      if (current != converted) {
        value = converted as T;
      }
      return;
    }

    // 3. 类型不匹配
    RxDebug.log(
      '❌ [类型错误] RxState(${name ?? id}): '
      '无法将 ${newValue.runtimeType} 赋值给 ${current.runtimeType}',
    );
  }

  /// 更新 Map 的特定 Key 或 List 的特定 Index。
  ///
  /// [field]: Map 的键或 List 的索引。
  /// [newValue]: 新的值。
  /// [notifyGlobal]: 是否同时触发监听 [value] 的全局监听器，默认为 false。
  void updateField<K extends Object>(K field, Object? newValue, {bool notifyGlobal = false}) {
    final current = _value;
    if (current == null) {
      RxDebug.log("⚠️ RxState(${name ?? id}) 值为 null，无法更新字段 $field");
      return;
    }

    if (current is Map && current.containsKey(field)) {
      final oldFieldValue = current[field];

      if (!_deepEquals(oldFieldValue, newValue)) {
        if (current is Map<String, Object>) {
          final newMap = Map<String, Object>.of(current);
          newMap[field as String] = newValue!;
          _value = newMap as T;
        } else if (current is Map<String, dynamic>) {
          final newMap = Map<String, dynamic>.of(current);
          newMap[field as String] = newValue!;
          _value = newMap as T;
        } else {
          // 兜底处理普通 Map
          final newMap = Map.from(current);
          newMap[field] = newValue;
          _value = newMap as T;
        }
        _notifyFieldListeners(field, notifyGlobal);
      }
      return;
    }
    // // ❌ List 直接禁止
    // if (current is List) {
    //   RxDebug.log("❌ List 不支持 field 更新，请使用 Map + key");
    //   return;
    // }

    if (current is List && field is int) {
      final index = field;

      if (index < 0 || index >= current.length) {
        RxDebug.log("⚠️ List index 越界: $index");
        return;
      }
      final oldItem = current[index];
      if (_deepEquals(oldItem, newValue)) return;

      final newList = (current as List).toList();
      newList[index] = newValue;
      _value = newList as T;

      _notifyFieldListeners(field, notifyGlobal);
      return;
    }

    // 只有走到这里，才说明是非容器类型，才考虑整体替换
    if (current != newValue) {
      if (newValue is T) {
        _value = newValue;
        _notifyListeners(id);
      } else {
        RxDebug.log('⚠️ RxState(${name ?? id}) 更新字段 $field 类型不匹配: 期望 $T，实际 ${newValue.runtimeType}');
      }
    }
  }

  // 添加字段监听器（支持任意 key 类型：int、String、Object）
  void addFieldListener(dynamic field, void Function(dynamic) listener) {
    _fieldListeners.putIfAbsent(field, () => []).add(listener);
  }

  // 移除字段监听器
  void removeFieldListener(dynamic field, void Function(dynamic) listener) {
    final fieldListeners = _fieldListeners[field];
    if (fieldListeners != null) {
      fieldListeners.remove(listener);
      // 清理空列表，减少内存占用
      if (fieldListeners.isEmpty) {
        _fieldListeners.remove(field);
      }
    }
  }

  void _notifyFieldListeners(dynamic field, bool notifyGlobal) {
    final listeners = _fieldListeners[field]?.toList();

    if (listeners != null && listeners.isNotEmpty) {
      dynamic fieldValue;

      if (_value is Map) {
        fieldValue = (_value as Map)[field];
      } else if (_value is List && field is int) {
        final list = _value as List;
        if (field >= 0 && field < list.length) {
          fieldValue = list[field];
        }
      }

      for (final l in listeners) {
        l(fieldValue);
      }
    }

    // ✅ 只有明确要求才触发全局
    if (notifyGlobal) {
      // print("→ 手动触发全局通知");
      _notifyListeners(id);
    }
  }

  void addListener(void Function(dynamic) listener) {
    if (!_listeners.contains(listener)) {
      _listeners.add(listener);
    }
  }

  void addListenerWithId(void Function(dynamic) listener) {
    if (!_listenersWithId.contains(listener)) {
      _listenersWithId.add(listener);
    }
  }

  /// 监听值变化，并立即执行一次 [onData]。
  ///
  /// 返回一个取消监听的函数。
  void Function() listen(void Function(T value) onData) {
    void wrapper(dynamic _) => onData(_value);
    _listeners.add(wrapper);
    // 立即触发一次，返回当前值
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
  void Function() listenWithId(void Function(T value, dynamic id) onData) {
    void wrapper(dynamic id) => onData(_value, id);

    _listenersWithId.add(wrapper);

    // 初始触发 this.
    onData(_value, id);

    bool disposed = false;
    return () {
      if (!disposed) {
        _listenersWithId.remove(wrapper);
        disposed = true;
      }
    };
  }

  // 按条件监听
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

    // ✅ 初始触发
    wrapper(_value);

    bool disposed = false;
    return () {
      if (!disposed) {
        _listeners.remove(wrapper);
        disposed = true;
      }
    };
  }

  /// 监听特定字段的变化。
  ///
  /// 适用于只想在 Map 的某个 Key 变化时才刷新的场景。
  void Function() listenByKey(dynamic key, void Function(dynamic value) onData) {
    void wrapper(dynamic value) => onData(value);

    addFieldListener(key, wrapper);

    // 初始值
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

  void removeListener(void Function(dynamic) listener) {
    _listeners.remove(listener);
  }

  void _notifyListeners(dynamic id) {
    // 倒序遍历可以安全地在循环中删除元素，且不产生额外对象
    // print("→ 执行全局监听器，数量: ${_listeners.length} , $_listeners");
    for (var i = _listeners.length - 1; i >= 0; i--) {
      _listeners[i](id);
    }
    // 🔹 带 id（高级用法）
    for (var i = _listenersWithId.length - 1; i >= 0; i--) {
      _listenersWithId[i](id);
    }
  }

  /// 销毁状态，清空所有监听器。
  void dispose() {
    _listeners.clear();
    _fieldListeners.clear();
    RxDebug.log("🧹 RxState(${name ?? id}) 已清理所有监听器");
  }

  /// 手动触发通知。
  void refresh() {
    _notifyListeners(id); // 这里的 notifyListeners 是继承自 ChangeNotifier 的
  }
}
