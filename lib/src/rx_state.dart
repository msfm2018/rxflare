import 'rx_track.dart';

int _rxStateCounter = 0;

class RxState<T> {
  final dynamic id;
  final String? name;
  T _value;
  final List<void Function(dynamic)> _listeners = [];
  final Map<dynamic, List<void Function(dynamic)>> _fieldListeners = {};

  RxState(this._value, {this.id, String? name}) : name = name ?? "RxState#${_rxStateCounter++}";

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

  void update(T newValue) => value = newValue;

  void updateField<K extends Object>(K field, dynamic newValue) {
    if (_value != null) {
      if (_value is Map) {
        if ((_value as Map).containsKey(field) && (_value as Map)[field] != newValue) {
          (_value as Map)[field] = newValue;
          _notifyFieldListeners(field);
        }
      } else if (_value is List && field is int) {
        if (field >= 0 && field < (_value as List).length && (_value as List)[field] != newValue) {
          (_value as List)[field] = newValue;
          _notifyFieldListeners(field);
        }
      } else {
        // 对于非 Map 和 List 的类型，我们只能进行整体更新
        if (_value != newValue) {
          _value = newValue;
          _notifyListeners(null);
        }
      }
    }
  }

  /// 添加字段监听器（支持任意 key 类型：int、String、Object）
  void addFieldListener(dynamic field, void Function(dynamic) listener) {
    _fieldListeners.putIfAbsent(field, () => []).add(listener);
  }

  /// 移除字段监听器
  void removeFieldListener(dynamic field, void Function(dynamic) listener) {
    _fieldListeners[field]?.remove(listener);
  }

  /// 触发字段监听器
  void _notifyFieldListeners(dynamic field) {
    _fieldListeners[field]?.forEach((listener) => listener(field));
    _notifyListeners(null); // 仍然触发整体监听器（防止依赖追踪遗漏）
  }

  void addListener(void Function(dynamic) listener) {
    _listeners.add(listener);
  }

// --- 新增 listen 接口 ---
  /// 监听值的变化，并立即返回当前最新的值
  /// 我们让它返回一个函数，方便外部取消监听（类似 StreamSubscription）
  void Function() listen(void Function(T value) onData) {
    // 包装一层，因为底层 _listeners 需要 dynamic id，但用户想要 T value
    void wrapper(dynamic _) => onData(_value);
    
    _listeners.add(wrapper);
    
    // 返回一个取消监听的闭包，这样更高级
    return () => _listeners.remove(wrapper);
  }

  /// 建议增加一个返回值，或者传回 field 本身
void listenField(dynamic field, void Function(dynamic value) onData) {
  addFieldListener(field, (_) {
    // 这里的 _ 其实就是传入的 field
    // 如果 _value 是 Map/List，我们可以考虑把具体的值传回去，而不是整个对象
    dynamic specificValue;
    if (_value is Map) {
      specificValue = (_value as Map)[field];
    } else if (_value is List && field is int) {
      specificValue = (_value as List)[field];
    } else {
      specificValue = _value;
    }
    onData(specificValue); 
  });
}

  void removeListener(void Function(dynamic) listener) {
    _listeners.remove(listener);
  }

  void _notifyListeners(dynamic id) {
    for (var listener in _listeners) {
      listener(id);
    }
  }

  void dispose() {
    _listeners.clear();
  }
}
