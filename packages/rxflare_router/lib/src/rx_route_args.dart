import 'dart:async';
import 'package:flutter/widgets.dart';

/// Represents a page instance in the navigation stack.
///
/// Contains route information, a unique page identifier,
/// and parsed route/query parameters.
class RxPage {
  /// Route name registered in the router.
  ///
  /// Usually the key used in the route map,
  /// for example: `/home`.
  final String name;

  /// Unique page identifier.
  ///
  /// Used for argument storage and result delivery.
  final String pageId;

  /// Path parameters extracted from the route.
  ///
  /// Example:
  /// `/detail/123` matched against `/detail/:id`
  /// produces `{id: "123"}`.
  final Map<String, String> params;

  /// Query parameters from the URL.
  ///
  /// Example:
  /// `/detail?id=123&type=test`
  /// produces:
  /// `{id: "123", type: "test"}`.
  final Map<String, String> query;

  RxPage({required this.name, required this.pageId, this.params = const {}, this.query = const {}});
}

/// Global page argument storage.
///
/// Stores custom objects associated with a page ID.
///
/// This is typically used to pass complex objects
/// during navigation without serializing them.
class RxArgs {
  RxArgs._();

  /// Singleton instance.
  static final I = RxArgs._();

  final Map<String, dynamic> _store = {};

  /// Stores arguments for the specified page.
  void set(String pageId, dynamic value) {
    _store[pageId] = value;
  }

  /// Retrieves arguments for the specified page.
  ///
  /// Returns `null` if no value exists.
  T? get<T>(String pageId) {
    return _store[pageId] as T?;
  }

  /// Removes stored arguments when a page is disposed.
  ///
  /// Prevents memory leaks caused by unused references.
  void remove(String pageId) {
    _store.remove(pageId);
  }
}

/// Handles route result delivery.
///
/// Internally uses [Completer] to support:
///
/// ```dart
/// final result = await rxr.to('/detail');
/// ```
class RxResult {
  static final _map = <String, Completer<dynamic>>{};

  /// Registers a pending result and returns a [Future].
  static Future<T?> wait<T>(String pageId) {
    final c = Completer<T?>();
    _map[pageId] = c;
    return c.future;
  }

  /// Completes a pending result and delivers the value.
  static void complete(String pageId, dynamic result) {
    _map.remove(pageId)?.complete(result);
  }
}

/// Route definition.
///
/// Describes how a route should be built
/// and optionally protected by a route guard.
class RxRoute {
  /// Widget builder for this route.
  final Widget Function() builder;

  /// Optional route guard.
  ///
  /// Return `false` to block navigation.
  final Future<bool> Function()? guard;

  /// Route path pattern.
  ///
  /// Supports dynamic segments:
  ///
  /// ```dart
  /// /detail/:id
  /// ```
  ///
  /// If omitted, the route map key will be used.
  final String? path;

  RxRoute({required this.builder, this.path, this.guard});
}

/// Result of a successful route match.
class RxHit {
  /// Matched route name.
  final String name;

  /// Extracted path parameters.
  final Map<String, String> params;

  RxHit(this.name, this.params);
}

/// Route matching utility.
///
/// Responsible for matching URLs against
/// registered route definitions and extracting
/// path parameters.
class RxMatcher {
  /// Attempts to match [input] against the route table.
  ///
  /// Returns an [RxHit] when a match is found,
  /// otherwise returns `null`.
  static RxHit? match(String input, Map<String, RxRoute> routes) {
    final inputUri = Uri.parse(input);
    final inputSegments = inputUri.pathSegments;

    for (final entry in routes.entries) {
      final def = entry.value;
      final pattern = Uri.parse(def.path ?? entry.key).pathSegments;

      if (pattern.length != inputSegments.length) continue;

      final params = <String, String>{};
      bool ok = true;

      for (int i = 0; i < pattern.length; i++) {
        final p = pattern[i];
        final v = inputSegments[i];

        if (p.startsWith(':')) {
          params[p.substring(1)] = v;
        } else if (p != v) {
          ok = false;
          break;
        }
      }

      if (ok) {
        return RxHit(entry.key, params);
      }
    }
    return null;
  }
}
