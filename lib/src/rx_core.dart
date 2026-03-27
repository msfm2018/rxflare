import 'rx_state.dart';

class _RxContext {
  final Set<RxState> states = {};
  final Map<RxState, Set<dynamic>> fields = {};
}

typedef RxValue<T> = RxState<T>;
typedef RxStore<T> = RxState<T>;
typedef RxNotifier<T> = RxState<T>;

typedef RxList<T> = RxState<List<T>>; 
typedef RxMap<K, V> = RxState<Map<K, V>>;