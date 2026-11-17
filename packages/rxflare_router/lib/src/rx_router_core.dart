import 'dart:async';

import 'package:flutter/widgets.dart';
import 'package:rxflare_core/rxflare_core.dart';

import 'rx_route_args.dart';

/// Global router instance for convenient access.
final rxr = RxRouter.I;

/// Utility class for generating unique page identifiers.
class RxUtils {
  static int _counter = 0;

  /// Generates a globally unique ID for distinguishing page instances.
  static String generateId() {
    _counter++;
    return 'rx_id_${DateTime.now().millisecondsSinceEpoch}_$_counter';
  }
}

/// **RxRouter** is the core manager of the RxFlare routing system.
///
/// It manages:
/// - Global route stack (`memPages`) for full-screen pages (login, home, dialogs, etc.)
/// - Tab-specific local stacks (`tabPages`)
/// - Navigation (`to`), back navigation (`back`), and parameter handling
class RxRouter {
  RxRouter._();
  String initialRoute = "/";
  final navigatorKey = GlobalKey<NavigatorState>();

  /// Singleton instance of [RxRouter].
  static final I = RxRouter._();

  /// Root route stack for global navigation (login, home, full-screen pages, etc.).
  final memPages = RxState<List<RxPage>>([]);

  /// Tab-specific route stacks. Key = tab index, Value = independent stack for that tab.
  final Map<int, RxState<List<RxPage>>> tabPages = {};

  /// Currently active tab index.
  final activeTabIndex = 0.rx;

  /// Tracks changes to the tabPages collection itself.
  final RxState<int> _tabRevision = RxState<int>(0);

  /// Registered route definitions.
  final _routes = <String, RxRoute>{};

  // =====================
  // Route Registration
  // =====================

  /// Registers a map of route definitions.
  ///
  /// [map] should contain path → [RxRoute] mappings.
  void register(Map<String, RxRoute> map) {
    for (var entry in map.entries) {
      final key = entry.key;
      final def = entry.value;

      final effectivePath = def.path ?? key;

      _routes[key] = RxRoute(
        builder: def.builder,
        path: effectivePath,
        guard: def.guard,
      );
    }
  }

  // =====================
  // Current State
  // =====================

  /// Returns the currently active route stack (tab stack or global stack).
  RxState<List<RxPage>> get _activePages {
    return tabPages[activeTabIndex.value] ?? memPages;
  }

  /// Returns the top page of the current active stack.
  RxPage? get current =>
      _activePages.value.isNotEmpty ? _activePages.value.last : null;

  /// Ensures the router is initialized with the initial route.
  void ensureInitialized() {
    if (memPages.value.isNotEmpty) return;

    memPages.value = [
      RxPage(
        name: initialRoute,
        pageId: RxUtils.generateId(),
        params: {},
        query: {},
      ),
    ];
  }

  // =====================
  // Navigation API
  // =====================

  /// Navigates to a new route.
  ///
  /// [path] can include path parameters (`/detail/123`) or query parameters (`/search?q=flutter`).
  /// [arguments] allows passing custom objects.
  ///
  /// Returns a [Future] that completes when the target page calls [back] with a result.
  Future<T?> to<T>(String path, {dynamic arguments}) async {
    final uri = Uri.parse(path);

    final match = RxMatcher.match(path, _routes);
    if (match == null) return null;

    final config = _routes[match.name]!;

    // Route guard check
    if (config.guard != null) {
      final ok = await config.guard!();
      if (!ok) return null;
    }

    final pageId = RxUtils.generateId();

    if (arguments != null) {
      _setArgs(pageId, arguments);
    }

    final memPage = RxPage(
      name: match.name,
      pageId: pageId,
      params: match.params,
      query: uri.queryParameters, //URL query
    );

    _activePages.value = [..._activePages.value, memPage];

    return RxResult.wait<T>(pageId);
  }

  // =====================
  // Replace & Clear Navigation APIs
  // =====================

  /// Replaces the current page with a new page.
  ///
  /// Removes the top page from the navigation stack and pushes
  /// the new page onto the stack.
  Future<T?> off<T>(String path, {dynamic arguments}) async {
    final uri = Uri.parse(path);
    final match = RxMatcher.match(path, _routes);
    if (match == null) return null;

    final config = _routes[match.name]!;
    if (config.guard != null) {
      final ok = await config.guard!();
      if (!ok) return null;
    }

    final pageId = RxUtils.generateId();
    if (arguments != null) {
      _setArgs(pageId, arguments);
    }

    final memPage = RxPage(
      name: match.name,
      pageId: pageId,
      params: match.params,
      query: uri.queryParameters,
    );

    // Core logic:
    // Copy the current stack, remove the top page,
    // then push the new page.
    final stack = List<RxPage>.from(_activePages.value);

    if (stack.isNotEmpty) {
      final removed = stack.removeLast();

      // Complete any pending result for the removed page.
      RxResult.complete(removed.pageId, null);

      // Clean up arguments associated with the removed page.
      _removeArgs(removed.pageId);
    }

    stack.add(memPage);

    _activePages.value = stack;

    return RxResult.wait<T>(pageId);
  }

  /// Clears the entire navigation stack and navigates
  /// to a new page.
  ///
  /// After calling this method, the new page becomes
  /// the only page in the stack.
  Future<T?> offAll<T>(String path, {dynamic arguments}) async {
    final uri = Uri.parse(path);
    final match = RxMatcher.match(path, _routes);
    if (match == null) return null;

    final config = _routes[match.name]!;
    if (config.guard != null) {
      final ok = await config.guard!();
      if (!ok) return null;
    }

    final pageId = RxUtils.generateId();
    if (arguments != null) {
      _setArgs(pageId, arguments);
    }

    final memPage = RxPage(
      name: match.name,
      pageId: pageId,
      params: match.params,
      query: uri.queryParameters,
    );

    // Clean up arguments for all existing pages
    // before resetting the stack.

    for (var page in _activePages.value) {
      // Complete any pending result for the removed page.
      RxResult.complete(page.pageId, null);

      // Clean up arguments associated with the removed page.
      _removeArgs(page.pageId);
    }
    // Replace the entire stack with a new stack
    // containing only the target page.
    _activePages.value = [memPage];

    return RxResult.wait<T>(pageId);
  }

  // =====================
  // Back Navigation
  // =====================

  /// Pops the current page.
  ///
  /// [result] will be returned to the waiting [to()] call if any.
  void back<T>({T? result}) {
    final stack = _activePages.value;
    if (stack.length > 1) {
      if (stack.isNotEmpty) {
        final newStack = List<RxPage>.from(stack);
        final removed = newStack.removeLast();

        _removeArgs(removed.pageId);
        RxResult.complete(removed.pageId, result);

        _activePages.value = newStack;
      }
    } else if (_activePages != memPages) {
      RxDebug.log("Tab stack reached bottom, cannot pop further internally.");
    }
  }

  // =====================
  // Parameter Access
  // =====================

  /// Gets custom arguments passed via [to()].
  T? args<T>() {
    final id = current?.pageId;
    if (id == null) return null;
    return RxArgs.I.get<T>(id);
  }

  /// Returns all query parameters (`?key=value`) of the current page.
  Map<String, String> query() {
    return current?.query ?? {};
  }

  /// Gets a specific query parameter.
  String? queryItem(String key) {
    return current?.query[key];
  }

  /// Returns all path parameters (`/user/:id`).
  Map<String, String> params() {
    return current?.params ?? {};
  }

  /// Gets a specific path parameter.
  String? param(String key) {
    return current?.params[key];
  }

  /// Returns current page ID (mainly for debugging).
  String? pageId() {
    return current?.pageId;
  }

  // =====================
  // Internal Argument Management
  // =====================
  void _setArgs(String pageId, dynamic value) {
    RxArgs.I.set(pageId, value);
  }

  void _removeArgs(String pageId) {
    RxArgs.I.remove(pageId);
  }

  // =====================
  // Tab Management
  // =====================

  /// Initializes a tab's route stack.
  /// Initializes a tab's route stack.
  void initTab(int index, List<RxPage> initial) {
    tabPages[index] = RxState(initial);

    // Notify delegates that a tab stack was added or replaced.
    _tabRevision.value++;
  }

  void initTabIfNeeded(int index, List<RxPage> initial) {
    if (tabPages[index] != null) return;

    tabPages[index] = RxState(initial);

    // Notify delegates that a new tab stack was created.
    _tabRevision.value++;
  }

  /// Switches the active tab.
  void switchTab(int index) {
    activeTabIndex.value = index;
  }
}

// =====================
// RouterDelegate & Parser (Navigator 2.0)
// =====================

/// Simple route configuration class (kept for compatibility).
class RxRouteConfig {
  final String? location;
  final dynamic state;

  RxRouteConfig({this.location, this.state});

  static RxRouteConfig home() => RxRouteConfig(location: '/');
}

/// RouterDelegate implementation that connects [RxRouter] state to Flutter's Navigator.
class RxRouterDelegate extends RouterDelegate<Object>
    with ChangeNotifier, PopNavigatorRouterDelegateMixin<Object> {
  @override
  GlobalKey<NavigatorState> get navigatorKey => RxRouter.I.navigatorKey;

  ///Specify a specific stack to listen to. If null, the global root stack and all Tab stacks are monitored by default.
  final RxState<List<RxPage>>? customStack;

  final List<void Function()> _unbinders = [];

  /// Tracks tab stacks that have already been subscribed.
  final Set<RxState<List<RxPage>>> _boundTabStacks = {};

  RxRouterDelegate({this.customStack}) {
    final router = RxRouter.I;

    router.ensureInitialized();

    final target = customStack ?? router.memPages;

    // Listen to the root stack or the custom stack.
    _unbinders.add(
      target.bind((_) => notifyListeners()),
    );

    // Global mode also needs to observe tab changes.
    if (customStack == null) {
      // 1. Listen to active tab changes.
      _unbinders.add(
        router.activeTabIndex.bind((_) {
          notifyListeners();
        }),
      );

      // 2. Listen to changes in the tabPages collection.
      _unbinders.add(
        router._tabRevision.bind((_) {
          _bindTabStacks(router);
          notifyListeners();
        }),
      );

      // 3. Subscribe to all existing tab stacks.
      _bindTabStacks(router);
    }
  }

  /// Subscribes to tab stacks that have not been observed yet.
  void _bindTabStacks(RxRouter router) {
    for (final stack in router.tabPages.values) {
      if (_boundTabStacks.add(stack)) {
        _unbinders.add(
          stack.bind((_) => notifyListeners()),
        );
      }
    }
  }

  @override
  void dispose() {
    for (var unbind in _unbinders) {
      unbind();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final router = RxRouter.I;
    // final stack = customStack?.value ?? router._activePages.value;
    final stack = customStack?.value ?? router.memPages.value;
    return Navigator(
      key: navigatorKey,
      pages: stack.map((e) {
        final config = router._routes[e.name];
        return RxPageRoute(
          key: ValueKey(e.pageId),
          child: _KeepAliveWrapper(
            child: config?.builder() ??
                const Center(
                  child: Text(
                    '404',
                    style: TextStyle(fontSize: 24),
                  ),
                ),
          ),
        );
      }).toList(),
      onDidRemovePage: (page) {
        final key = page.key;
        if (key is ValueKey<String>) {
          final pageId = key.value;
          if (RxRouter.I.pageId() == pageId) {
            RxRouter.I.back();
          }
        }
      },
    );
  }

  //When notifyListeners () is called, the Router will read this configuration and synchronize it to the browser address bar.

  @override
  Object? get currentConfiguration {
    // final stack = customStack?.value ?? RxRouter.I._activePages.value;
    final stack = customStack?.value ?? RxRouter.I.memPages.value;
    if (stack.isEmpty) return "/";

    final lastPage = stack.last;
    final router = RxRouter.I;

    // 获取注册时定义的路由模板，例如 /detail/:id。
    final config = router._routes[lastPage.name];
    final routePattern = config?.path ?? lastPage.name;

    // 根据路径参数还原动态路径段。
    final segments = Uri.parse(routePattern).pathSegments;

    final restoredSegments = segments.map((segment) {
      if (segment.startsWith(':')) {
        final key = segment.substring(1);
        final value = lastPage.params[key];

        if (value != null) {
          return Uri.encodeComponent(value);
        }
      }

      return Uri.encodeComponent(segment);
    }).toList();

    final path =
        restoredSegments.isEmpty ? '/' : '/${restoredSegments.join('/')}';

    // 恢复 Query 参数。
    if (lastPage.query.isEmpty) {
      return path;
    }

    final queryString = Uri(queryParameters: lastPage.query).query;

    return '$path?$queryString';
  }

  //Flutter calls this method when the browser clicks Back.
  // @override
  // Future<void> setNewRoutePath(Object configuration) async {
  //   final path = configuration.toString();
  //   //Logic: If the path requested by the browser is different from the current stack top, jump is executed.
  //   if (RxRouter.I.current?.name != path) {
  //     RxRouter.I.to(path);
  //   }
  // }

  // @override
  // Future<void> setNewRoutePath(Object configuration) async {
  //   final path = configuration.toString();
  //   if (currentConfiguration != path) {
  //     RxRouter.I.to(path);
  //   }
  // }

  /// 将指定页面还原成浏览器地址。
  String _locationForPage(RxPage page) {
    final router = RxRouter.I;
    final config = router._routes[page.name];
    final routePattern = config?.path ?? page.name;

    final segments = Uri.parse(routePattern).pathSegments;

    final restoredSegments = segments.map((segment) {
      if (segment.startsWith(':')) {
        final key = segment.substring(1);
        final value = page.params[key];

        if (value != null) {
          return Uri.encodeComponent(value);
        }
      }

      return Uri.encodeComponent(segment);
    }).toList();

    final path =
        restoredSegments.isEmpty ? '/' : '/${restoredSegments.join('/')}';

    if (page.query.isEmpty) {
      return path;
    }

    final queryString = Uri(queryParameters: page.query).query;
    return '$path?$queryString';
  }

  @override
  Future<void> setNewRoutePath(Object configuration) async {
    final router = RxRouter.I;
    final path = configuration.toString();

    // 当前地址相同，不重复导航。
    if (currentConfiguration == path) {
      return;
    }

    final stack = customStack?.value ?? router.memPages.value;

    // 浏览器后退：目标地址是当前页面的上一页。
    if (customStack == null && stack.length > 1) {
      final previousPage = stack[stack.length - 2];
      final previousLocation = _locationForPage(previousPage);

      if (previousLocation == path) {
        router.back();
        return;
      }
    }

    // 普通浏览器导航：打开新地址。
    // 不能 await，因为 router.to() 会等待页面返回结果。
    // unawaited(router.to(path));

    final navigation = router.to(path);

    unawaited(
      navigation.then<void>(
        (_) {
          // Guard 拒绝、路由不存在或页面返回后，
          // 如果当前地址与目标地址不同，则重新同步地址栏。
          if (currentConfiguration != path) {
            notifyListeners();
          }
        },
        onError: (Object error, StackTrace stackTrace) {
          notifyListeners();
        },
      ),
    );
  }
}

class RxRouteParser extends RouteInformationParser<Object> {
  @override
  Future<Object> parseRouteInformation(
    RouteInformation routeInformation,
  ) async {
    return routeInformation.uri.toString();
  }

  @override
  RouteInformation restoreRouteInformation(Object configuration) {
    return RouteInformation(uri: Uri.parse(configuration as String));
  }
}

/// Internal wrapper to keep page state alive when switching tabs.
class _KeepAliveWrapper extends StatefulWidget {
  final Widget child;
  const _KeepAliveWrapper({required this.child});

  @override
  State<_KeepAliveWrapper> createState() => _KeepAliveWrapperState();
}

class _KeepAliveWrapperState extends State<_KeepAliveWrapper>
    with AutomaticKeepAliveClientMixin {
  @override
  bool get wantKeepAlive => true;

  @override
  Widget build(BuildContext context) {
    super.build(context);
    return widget.child;
  }
}

/// A style-agnostic page that does not depend on Material or Cupertino.
class RxPageRoute extends Page {
  final Widget child;

  const RxPageRoute({
    required this.child,
    super.key,
    super.name,
    super.arguments,
    super.restorationId,
  });

  @override
  Route createRoute(BuildContext context) {
    return PageRouteBuilder(
      settings: this,
      pageBuilder: (context, animation, secondaryAnimation) => child,
      transitionsBuilder: (context, animation, secondaryAnimation, child) {
        // 简单的淡入淡出，完全中性，不带任何平台风格
        return FadeTransition(
          opacity: animation,
          child: child,
        );
      },
    );
  }
}
