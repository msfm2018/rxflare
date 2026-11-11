import 'package:flutter_test/flutter_test.dart';
import 'package:rxflare/rxflare.dart';


void main() {
  group('RxList Dependency Tracking', () {
    test('读取 list[0] 只注册 Index 0 依赖', () {
      final list = RxList<int>([10, 20, 30]);
      final context = RxContext();

      RxStack.push(context);

      try {
        final result = list[0];

        expect(result, 10);
        expect(context.states, isEmpty);
        expect(context.fields[list], contains(0));
        expect(context.fields[list], isNot(contains(1)));
      } finally {
        RxStack.pop();
      }
    });

    test('读取 list[1] 只注册 Index 1 依赖', () {
      final list = RxList<int>([10, 20, 30]);
      final context = RxContext();

      RxStack.push(context);

      try {
        final result = list[1];

        expect(result, 20);
        expect(context.states, isEmpty);
        expect(context.fields[list], contains(1));
      } finally {
        RxStack.pop();
      }
    });

    test('读取 list.value 注册整体依赖', () {
      final list = RxList<int>([10, 20, 30]);
      final context = RxContext();

      RxStack.push(context);

      try {
        final result = list.value;

        expect(result, [10, 20, 30]);
        expect(context.states, contains(list));
        expect(context.fields.containsKey(list), isFalse);
      } finally {
        RxStack.pop();
      }
    });

    test('同时读取整体和 Index 应分别注册两种依赖', () {
      final list = RxList<int>([10, 20, 30]);
      final context = RxContext();

      RxStack.push(context);

      try {
        final all = list.value;
        final item = list[1];

        expect(all, [10, 20, 30]);
        expect(item, 20);

        expect(context.states, contains(list));
        expect(context.fields[list], contains(1));
      } finally {
        RxStack.pop();
      }
    });

    test('修改 Index 不应该产生依赖收集', () {
      final list = RxList<int>([10, 20, 30]);
      final context = RxContext();

      RxStack.push(context);

      try {
        list[0] = 100;

        expect(context.states, isEmpty);
        expect(context.fields, isEmpty);
      } finally {
        RxStack.pop();
      }
    });
  });
}