import 'package:flutter_test/flutter_test.dart';
import 'package:rxflare_core/rxflare_core.dart';

void main() {
  group('RxState listener after dispose reproduction', () {
    test('listen should reveal registration after dispose', () {
      final state = RxState<int>(1);
      state.dispose();

      var count = 0;

      state.listen((value) {
        count++;
        // ignore: avoid_print
        print('listen 收到: $value');
      });
      // ignore: avoid_print
      print('listen 初始回调次数: $count');

      // 当前实现：dispose 后仍然执行初始回调。
      expect(count, 0);

      state.notifyListenersNow();
      // ignore: avoid_print
      print('listen 再次通知次数: $count');

      // 当前实现：dispose 后仍然可以注册全局监听器。
      expect(count, 0);
    });

    test('bind should reveal registration after dispose', () {
      final state = RxState<int>(1);
      state.dispose();

      var count = 0;

      state.bind((value) {
        count++;
        // ignore: avoid_print
        print('bind 收到: $value');
      });
      // ignore: avoid_print
      print('bind 注册后回调次数: $count');

      expect(count, 0);

      state.notifyListenersNow();
      // ignore: avoid_print
      print('bind 通知后回调次数: $count');

      // 当前实现：dispose 后仍然注册成功。
      expect(count, 0);
    });

    test('listenWithId should reveal registration after dispose', () {
      final state = RxState<int>(1);
      state.dispose();

      var count = 0;

      state.listenWithId((value, id) {
        count++;
        // ignore: avoid_print
        print('listenWithId 收到: $value, id: $id');
      });
      // ignore: avoid_print
      print('listenWithId 初始回调次数: $count');

      expect(count, 0);

      state.notifyListenersNow();
      // ignore: avoid_print
      print('listenWithId 再次通知次数: $count');

      expect(count, 0);
    });

    test('listenByKey should reveal callback after dispose', () {
      final state = RxState<List<int>>([10, 20]);
      state.dispose();

      var count = 0;

      state.listenByKey(0, (value) {
        count++;
        // ignore: avoid_print
        print('listenByKey 收到: $value');
      });
      // ignore: avoid_print
      print('listenByKey 初始回调次数: $count');

      // 当前实现：即使已经 dispose，仍执行初始回调。
      expect(count, 0);

      state.notifyFieldNow(0);
      // ignore: avoid_print
      print('listenByKey 再次通知次数: $count');

      // addFieldListener 有 disposed 检查，所以没有真正注册成功。
      expect(count, 0);
    });
  });
}
