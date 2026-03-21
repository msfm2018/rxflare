import 'package:flutter_test/flutter_test.dart';

import 'package:rxflare/rxflare.dart';

void main() {
  test('adds one to input values', () {
    final calculator = Calculator();
    expect(calculator.addOne(2), 3);
    expect(calculator.addOne(-7), -6);
    expect(calculator.addOne(0), 1);
  });
}



RxState + .obs：基础响应式变量。

Rx：自动刷新的 UI 组件。

RxEventBus：强大的异步事件总线。

RxComputed：智能的计算属性。