import 'package:flutter/material.dart';

import 'rx_state.dart';

class RxFuture<T> extends RxState<AsyncSnapshot<T>> {
  RxFuture(Future<T> future) : super(const AsyncSnapshot.nothing()) {
    _subscribe(future);
  }

  void _subscribe(Future<T> future) {
    value = const AsyncSnapshot.waiting();
    future
        .then((data) {
          value = AsyncSnapshot.withData(ConnectionState.done, data);
        })
        .catchError((error) {
          value = AsyncSnapshot.withError(ConnectionState.done, error);
        });
  }

  void refresh(Future<T> future) {
    _subscribe(future);
  }
}
