import 'package:flutter/foundation.dart';
import 'rx_track.dart';
import 'rx_debug.dart';

int _rxStateCounter = 0;

class RxState<T> {
  final dynamic id;
  final String? name;
  T _value;
  final List<void Function(dynamic)> _listeners = [];
  final Map<dynamic, List<void Function(dynamic)>> _fieldListeners = {};
  RxState(this._value, {dynamic id, String? name})
      : id = id ?? Object(),
        name = name ?? "RxState#$_rxStateCounter" {
    _rxStateCounter++;
  }

  T get value {
    RxTrack.register(this);
    return _value;
  }

  set value(T newValue) {
    if (!_deepEquals(_value, newValue)) {
      _value = newValue;
      _notifyListeners(id);
    }
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

  bool _deepEquals(dynamic a, dynamic b) {
    if (a is Map && b is Map) return mapEquals(a, b); // 需要 import 'package:flutter/foundation.dart';
    if (a is List && b is List) return listEquals(a, b);
    return a == b;
  }
  // void update2(T newValue) => value = newValue;

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
      RxDebug.log(
        "⚠️ RxState(${name ?? id}): double → int 可能丢失精度: $newValue",
      );

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

  void updateField<K extends Object>(
    K field,
    Object? newValue, {
    bool notifyGlobal = true,
  }) {
    // 改成 Object? 更宽松
    final current = _value;
    if (current == null) {
      RxDebug.log("⚠️ RxState(${name ?? id}) 值为 null，无法更新字段 $field");
      return;
    }

    // ─────────────── 核心改动在这里 ───────────────
    if (current is Map && current.containsKey(field)) {
      final oldFieldValue = current[field];
      if (!_deepEquals(oldFieldValue, newValue)) {
        final newMap = {...current};
        newMap[field] = newValue;

        _value = newMap as T;

        _notifyFieldListeners(field, notifyGlobal);
      }
      return; // 已经处理了 Map 情况，直接返回
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

    if (listeners != null) {
      final map = _value as Map;
      final fieldValue = map[field];

      for (final l in listeners) {
        l(fieldValue);
      }
    }
    if (notifyGlobal) {
      // ✅ 永远触发全局监听
      _notifyListeners(id);
    }
  }

  void addListener(void Function(dynamic) listener) {
    if (!_listeners.contains(listener)) {
      _listeners.add(listener);
    }
  }

  // 监听值的变化，并立即返回当前最新的值
  // 返回一个函数，方便外部取消监听（类似 StreamSubscription）
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

// ✅ 新增：按条件监听（核心能力）
  void Function() listenWhere(
    bool Function(dynamic item) test,
    void Function(dynamic item) onData,
  ) {
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

// ✅ listenByKey：按 key 监听 Map 中的值变化 丢弃 list数据监控 index 会随时变化不稳定
  void Function() listenByKey(
    dynamic key,
    void Function(dynamic value) onData,
  ) {
    if (_value is! Map) {
      RxDebug.log("❌ listenByKey 只能用于 Map");
      return () {};
    }

    void wrapper(dynamic value) => onData(value);

    addFieldListener(key, wrapper);

    // 初始值
    final map = _value as Map;
    onData(map[key]);

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
    for (var i = _listeners.length - 1; i >= 0; i--) {
      _listeners[i](id);
    }
  }

  // 清理所有监听器，防止内存泄漏
  void dispose() {
    _listeners.clear();
    _fieldListeners.clear();
    RxDebug.log("🧹 RxState(${name ?? id}) 已清理所有监听器");
  }

  void refresh() {
    _notifyListeners(id); // 这里的 notifyListeners 是继承自 ChangeNotifier 的
  }
}
