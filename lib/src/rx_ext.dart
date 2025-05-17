// rx_extensions.dart

import 'rx_state.dart';

extension RxExtension<T> on T {
  RxState<T> get rx => RxState<T>(this);
}

extension RxStateListHelper<T> on RxState<List<T>> {
  void add(T item) {
    value.add(item);
    update(value); // 触发更新
  }

  void remove(T item) {
    value.remove(item);
    update(value);
  }
}
//list.add("张三"); 自动更新