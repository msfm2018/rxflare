import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rxflare_router/rxflare_router.dart';

RxRoute _route({String? path}) {
  return RxRoute(path: path, builder: () => const SizedBox());
}

void main() {
  group('RxRoute', () {
    test('path and guard default to null', () {
      final route = _route();

      expect(route.path, isNull);
      expect(route.guard, isNull);
    });

    test('keeps the provided path and guard', () {
      Future<bool> guard() async => true;

      final route = RxRoute(
        path: '/detail/:id',
        guard: guard,
        builder: () => const SizedBox(),
      );

      expect(route.path, '/detail/:id');
      expect(route.guard, same(guard));
    });
  });

  group('RxHit', () {
    test('stores name and params', () {
      final hit = RxHit('/detail', {'id': '1'});

      expect(hit.name, '/detail');
      expect(hit.params, {'id': '1'});
    });
  });

  group('RxMatcher.match', () {
    test('matches the root path', () {
      final routes = {'/': _route(), '/home': _route()};

      final hit = RxMatcher.match('/', routes)!;

      expect(hit.name, '/');
      expect(hit.params, isEmpty);
    });

    test('matches a static path', () {
      final routes = {'/': _route(), '/home': _route()};

      final hit = RxMatcher.match('/home', routes)!;

      expect(hit.name, '/home');
      expect(hit.params, isEmpty);
    });

    test('returns null when nothing matches', () {
      final routes = {'/': _route(), '/home': _route()};

      expect(RxMatcher.match('/nope', routes), isNull);
    });

    test('returns null for an empty route table', () {
      expect(RxMatcher.match('/home', {}), isNull);
    });

    test('returns null when the segment count differs', () {
      final routes = {'/home': _route()};

      expect(RxMatcher.match('/home/extra', routes), isNull);
    });

    test('extracts a dynamic path parameter', () {
      final routes = {'/user/:id': _route()};

      final hit = RxMatcher.match('/user/42', routes)!;

      expect(hit.name, '/user/:id');
      expect(hit.params, {'id': '42'});
    });

    test('extracts several dynamic path parameters', () {
      final routes = {'/shop/:shopId/item/:itemId': _route()};

      final hit = RxMatcher.match('/shop/s1/item/i2', routes)!;

      expect(hit.params, {'shopId': 's1', 'itemId': 'i2'});
    });

    test('returns null when a literal segment does not match', () {
      final routes = {'/shop/:shopId/item/:itemId': _route()};

      expect(RxMatcher.match('/shop/s1/order/i2', routes), isNull);
    });

    test('uses RxRoute.path instead of the map key when provided', () {
      final routes = {'/detail': _route(path: '/detail/:id')};

      final hit = RxMatcher.match('/detail/9', routes)!;

      // name 是 map 的 key，匹配规则来自 path。
      expect(hit.name, '/detail');
      expect(hit.params, {'id': '9'});

      // key 本身（/detail）因为段数不同，不再匹配。
      expect(RxMatcher.match('/detail', routes), isNull);
    });

    test('ignores the query string when matching', () {
      final routes = {'/home': _route(), '/user/:id': _route()};

      expect(RxMatcher.match('/home?x=1', routes)!.name, '/home');

      final hit = RxMatcher.match('/user/7?tab=a', routes)!;
      expect(hit.params, {'id': '7'});
    });

    test('decodes percent-encoded path parameters', () {
      final routes = {'/user/:name': _route()};

      final hit = RxMatcher.match('/user/hello%20world', routes)!;

      expect(hit.params, {'name': 'hello world'});
    });

    test('the first matching route in insertion order wins', () {
      final dynamicFirst = {'/user/:id': _route(), '/user/me': _route()};
      final staticFirst = {'/user/me': _route(), '/user/:id': _route()};

      expect(RxMatcher.match('/user/me', dynamicFirst)!.name, '/user/:id');
      expect(RxMatcher.match('/user/me', staticFirst)!.name, '/user/me');
    });
  });
}
