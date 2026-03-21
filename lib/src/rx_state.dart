import 'rx_track.dart';
import 'rx_debug.dart';

int _rxStateCounter = 0;

class RxState<T> {
  final dynamic id;
  final String? name;
  T _value;
  final List<void Function(dynamic)> _listeners = [];
  final Map<dynamic, List<void Function(dynamic)>> _fieldListeners = {};
  RxState(this._value, {dynamic id, String? name}) : id = id ?? Object(), name = name ?? "RxState#$_rxStateCounter" {
    _rxStateCounter++;
  }

  T get value {
    RxTrack.register(this);
    return _value;
  }

  set value(T newValue) {
    if (_value != newValue) {
      _value = newValue;
      _notifyListeners(id);
    }
  }

/// 内部监听接口：供 RxComputed 等组件绑定依赖
  /// 它不触发 RxTrack 追踪，只是纯粹的观察者回调
  void addInternalListener(void Function(dynamic) listener) {
    if (!_listeners.contains(listener)) {
      _listeners.add(listener);
    }
  }
// 2. 这里的 internalUpdate 就是 RxComputed 会调用的“后门”
  void internalUpdate(T newValue) {
    if (_value != newValue) {
      _value = newValue;
      _notifyListeners(id); // 📢 现在这里可以正常调用了
    }
  }
  
  // void update2(T newValue) => value = newValue;

void update(dynamic newValue) {
  final current = _value;

  /// 1. 完全匹配类型
  if (newValue is T) {
    if (current != newValue) {
      value = newValue;
    }
    return;
  }

  /// 2. 数值类型兼容（推荐用 current 判断）
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

  /// 3. 类型不匹配
  RxDebug.log(
    '❌ [类型错误] RxState(${name ?? id}): '
    '无法将 ${newValue.runtimeType} 赋值给 ${current.runtimeType}',
  );
}


  void updateField<K extends Object>(K field, Object? newValue) {
    // 改成 Object? 更宽松
    final current = _value;
    if (current == null) {
      RxDebug.log("⚠️ RxState(${name ?? id}) 值为 null，无法更新字段 $field");
      return;
    }

    // ─────────────── 核心改动在这里 ───────────────
    if (current is Map && current.containsKey(field)) {
      if (current[field] != newValue) {
        current[field] = newValue;
        _notifyFieldListeners(field);
      }
      return; // 已经处理了 Map 情况，直接返回
    }

    if (current is List && field is int) {
      if (field >= 0 && field < current.length) {
        if (current[field] != newValue) {
          current[field] = newValue;
          _notifyFieldListeners(field);
        }
      } else {
        RxDebug.log("⚠️ RxState(${name ?? id}) 列表索引 $field 越界，长度: ${current.length}");
      }
      return;
    }

    // 只有走到这里，才说明是非容器类型，才考虑整体替换
    if (current != newValue) {
      if (newValue is T) {
        _value = newValue as T;
        _notifyListeners(id);
      } else {
        RxDebug.log('⚠️ RxState(${name ?? id}) 更新字段 $field 类型不匹配: 期望 $T，实际 ${newValue.runtimeType}');
      }
    }
  }


  /// 添加字段监听器（支持任意 key 类型：int、String、Object）
  void addFieldListener(dynamic field, void Function(dynamic) listener) {
    _fieldListeners.putIfAbsent(field, () => []).add(listener);
  }

  /// 移除字段监听器
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

  /// 触发字段监听器
  void _notifyFieldListeners(dynamic field) {
    dynamic fieldValue;
    if (_value is Map) {
      fieldValue = (_value as Map)[field];
    } else if (_value is List && field is int) {
      fieldValue = (_value as List)[field];
    } else {
      fieldValue = _value;
    }

    // 触发字段专属监听器（遍历副本，避免遍历中修改）
    _fieldListeners[field]?.toList().forEach((listener) => listener(fieldValue));
    // 触发整体监听器（保证依赖追踪不遗漏）
    _notifyListeners(id);
  }

  void addListener(void Function(dynamic) listener) {
    if (!_listeners.contains(listener)) {
      _listeners.add(listener);
    }
  }

  /// 监听值的变化，并立即返回当前最新的值
  /// 返回一个函数，方便外部取消监听（类似 StreamSubscription）
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

  /// 监听字段变化，支持取消监听
  void Function() listenField(dynamic field, void Function(dynamic value) onData) {
    void wrapper(dynamic value) => onData(value);
    addFieldListener(field, wrapper);

    // 立即返回当前字段值
    dynamic initialValue;
    if (_value is Map) {
      initialValue = (_value as Map)[field];
    } else if (_value is List && field is int) {
      initialValue = (_value as List)[field];
    } else {
      initialValue = _value;
    }
    onData(initialValue);

    // 增加防重复调用标记
    bool _cancelled = false;
    return () {
      if (!_cancelled) {
        removeFieldListener(field, wrapper);
        _cancelled = true;
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

  /// 清理所有监听器，防止内存泄漏
  void dispose() {
    _listeners.clear();
    _fieldListeners.clear();
    RxDebug.log("🧹 RxState(${name ?? id}) 已清理所有监听器");
  }
}
