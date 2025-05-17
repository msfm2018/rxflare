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
