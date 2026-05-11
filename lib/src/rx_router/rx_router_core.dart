// memPages: 负责大局（登录、主页、全屏详情）。
// tabPages: 负责局部。
// back: 优先处理当前视口（Active），如果触底则报警/扩展。

import 'package:flutter/material.dart';
import 'package:rxflare/src/core/rx_core.dart';

import '../core/rx_state.dart';
import '../utils/rx_debug.dart';
import './rx_route_args.dart';

/// 全局路由便捷访问实例。
final rxr = RxRouter.I;

class RxUtils {
  static int _counter = 0;

  // /// 生成全局唯一的标识符，用于区分不同的页面实例。
  static String generateId() {
    _counter++;
    return 'rx_id_${DateTime.now().millisecondsSinceEpoch}_$_counter';
  }
}

/// RxRouter 是 RxFlare 路由系统的核心管理器。
///
/// 它负责管理全局路由栈 ([memPages])、多 Tab 局部栈 ([tabPages])、
/// 路由跳转 ([to])、返回 ([back]) 以及参数存取。
class RxRouter {
  RxRouter._();
  String initialRoute = "/";
  final navigatorKey = GlobalKey<NavigatorState>();

  /// 获取 RxRouter 的单例实例。
  static final I = RxRouter._();

  // final _uuid = RxUtils.generateId(); // const Uuid();

  ///  根路由栈。负责全局大局逻辑，如：登录页、主页、全屏弹窗等。
  final memPages = RxState<List<RxPage>>([]);

  /// 多 Tab 局部栈集合。Key 为 Tab 索引，Value 为该 Tab 独立的路由栈。
  final Map<int, RxState<List<RxPage>>> tabPages = {};

  /// 当前激活的 Tab 索引。
  final activeTabIndex = 0.obs;

  /// 已注册的路由配置映射表。
  final _routes = <String, RxDef>{};

  // =====================
  // 注册
  // =====================

  /// 注册路由定义表。
  ///
  /// [map] 包含路径与对应的构建器及守卫逻辑。
  // void register(Map<String, RxDef> map) {
  //   _routes.addAll(map);
  // }
  void register(Map<String, RxDef> map) {
    for (var entry in map.entries) {
      final key = entry.key;
      final def = entry.value;

      // 如果用户没传 path，则使用 key 作为 path
      final effectivePath = def.path ?? key;

      _routes[key] = RxDef(
        builder: def.builder,
        path: effectivePath, // 内部统一保存
        guard: def.guard,
      );
    }
  }

  // =====================
  // 当前状态
  // =====================
  /// 获取当前活跃的路由栈（根据 [activeTabIndex] 自动选择 Tab 栈或根栈）。
  RxState<List<RxPage>> get _activePages {
    return tabPages[activeTabIndex.value] ?? memPages;
  }

  /// 获取当前视口顶部的页面信息。
  RxPage? get current => _activePages.value.isNotEmpty ? _activePages.value.last : null;

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
  // 跳转 API
  // =====================

  /// 跳转至指定路径。
  ///
  /// [path] 支持带参数的路径（如 `/detail/123`）或带 Query 的路径（如 `/search?q=flutter`）。
  /// [arguments] 可选的自定义参数对象。
  ///
  /// 返回一个 [Future]，可在目标页面调用 [back] 时获取返回值。
  Future<T?> to<T>(String path, {dynamic arguments}) async {
    final uri = Uri.parse(path);

    final match = RxHiter.match(path, _routes);
    if (match == null) return null;

    final config = _routes[match.name]!;

    //  路由守卫检查
    if (config.guard != null) {
      final ok = await config.guard!();
      if (!ok) return null;
    }

    final pageId = RxUtils.generateId();

    if (arguments != null) {
      // RxArgs.I.set(pageId, arguments);
      _setArgs(pageId, arguments);
    }

    final memPage = RxPage(
      name: match.name,
      pageId: pageId,
      params: match.params, //  路径参数
      query: uri.queryParameters, //URL query
    );

    _activePages.value = [..._activePages.value, memPage];

    return RxRes.wait<T>(pageId);
  }

  // =====================
  // 返回 API
  // =====================

  /// 返回上一页。
  ///
  /// [result] 可选的回传给 [to] 方法的等待者的值。
  void back<T>({T? result}) {
    final stack = _activePages.value;
    // if (stack.length <= 1) return;
    if (stack.length > 1) {
      if (stack.isNotEmpty) {
        // 增加一层判空保护
        final newStack = List<RxPage>.from(stack);
        final removed = newStack.removeLast();

        _removeArgs(removed.pageId);
        RxRes.complete(removed.pageId, result);

        _activePages.value = newStack;
      }
    } else if (_activePages != memPages) {
      // 2. 如果当前在 Tab 栈且已经到底了，尝试切换回全局主栈逻辑 (可选)
      // 这里取决于你的业务：是关掉整个 Tab 页面，还是切换 activeTabIndex
      RxDebug.log(" Tab 栈已到顶，无法继续在内部 back");
    }
  }

  // =====================
  // 参数访问 API
  // =====================

  /// 获取当前页面的自定义参数对象。
  T? args<T>() {
    final id = current?.pageId;
    if (id == null) return null;
    return RxArgs.I.get<T>(id);
  }

  // =====================
  // query 参数（?id=123）  获取当前页面的所有 Query 参数。
  // =====================
  Map<String, String> query() {
    return current?.query ?? {};
  }

  /// 获取指定 Key 的 Query 参数值。
  String? queryItem(String key) {
    return current?.query[key];
  }

  // =====================
  // path 参数（/user/:id）
  // =====================
  Map<String, String> params() {
    return current?.params ?? {};
  }

  /// 获取指定 Key 的路径参数值。
  String? param(String key) {
    return current?.params[key];
  }

  // =====================
  // 当前 pageId（调试用）
  // =====================
  String? pageId() {
    return current?.pageId;
  }

  // =====================
  // 参数存储 API（内部）
  // =====================
  void _setArgs(String pageId, dynamic value) {
    RxArgs.I.set(pageId, value);
  }

  void _removeArgs(String pageId) {
    RxArgs.I.remove(pageId);
  }

  // =====================
  // Tab 管理
  // =====================

  /// 初始化指定索引的 Tab 路由栈。
  ///
  /// [index] Tab 索引。
  /// [initial] 初始页面列表。
  void initTab(int index, List<RxPage> initial) {
    tabPages[index] = RxState(initial);
  }

  void initTabIfNeeded(int index, List<RxPage> initial) {
    if (tabPages[index] != null) return;

    tabPages[index] = RxState(initial);
  }

  /// 切换当前激活的 Tab。
  void switchTab(int index) {
    activeTabIndex.value = index;
  }
}

/// 适配 Navigator 2.0 的路由委托类。
///
/// 负责将 [RxRouter] 中的状态映射为 Flutter 的 [Navigator] 页面栈。
class RxRouteConfig {
  final String? location;
  final dynamic state;

  RxRouteConfig({this.location, this.state});

  static RxRouteConfig home() => RxRouteConfig(location: '/');
}

class RxRouterDelegate extends RouterDelegate<Object> with ChangeNotifier, PopNavigatorRouterDelegateMixin<Object> {
  @override
  final navigatorKey = GlobalKey<NavigatorState>();

  /// 指定监听的特定栈。如果为 null，则默认监听全局根栈及所有 Tab 栈。
  final RxState<List<RxPage>>? customStack;

  final List<void Function()> _unbinders = [];

  RxRouterDelegate({this.customStack}) {
    RxRouter.I.ensureInitialized();

    final target = customStack ?? RxRouter.I.memPages;

    // 绑定状态变化，自动通知 Flutter 重新构建
    _unbinders.add(target.bind((_) => notifyListeners()));

    // 全局模式下绑定所有 Tab
    if (customStack == null) {
      for (var s in RxRouter.I.tabPages.values) {
        _unbinders.add(s.bind((_) => notifyListeners()));
      }
    }
  }

  @override
  void dispose() {
    // 销毁 Delegate 时，自动解除所有 RxState 的绑定
    for (var unbind in _unbinders) {
      unbind();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final router = RxRouter.I;
    // 使用指定的栈，如果没有则使用全局逻辑
    final stack = customStack?.value ?? router._activePages.value;
    return Navigator(
      key: navigatorKey,
      pages: stack.map((e) {
        final config = router._routes[e.name];
        return MaterialPage(
          key: ValueKey(e.pageId),
          child: _KeepAliveWrapper(
            child: config?.builder() ?? const Scaffold(body: Center(child: Text("404"))),
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

  // 【新增】重写这个属性是关键！
  // 当 notifyListeners() 被调用时，Router 会读取这个配置并同步到浏览器地址栏
  @override
  Object? get currentConfiguration {
    final stack = customStack?.value ?? RxRouter.I._activePages.value;
    if (stack.isEmpty) return "/";

    // 找到当前页面的完整路径（包含 query）
    final lastPage = stack.last;
    var path = lastPage.name;

    // 如果有路径参数，需要还原它（例如将 /detail 和 {id:123} 还原为 /detail/123）
    // 这里简单处理，或者直接从你的 RxPage 里存一个完整原始路径
    return path;
  }

  // 当浏览器点击后退时，Flutter 会调用这个方法
  @override
  Future<void> setNewRoutePath(Object configuration) async {
    final path = configuration.toString();
    // 逻辑：如果浏览器请求的路径和当前栈顶不同，则执行跳转
    if (RxRouter.I.current?.name != path) {
      RxRouter.I.to(path);
    }
  }
}

class RxRouteParser extends RouteInformationParser<Object> {
  @override
  Future<Object> parseRouteInformation(RouteInformation routeInformation) async {
    return routeInformation.uri.toString();
  }

  @override
  RouteInformation restoreRouteInformation(Object configuration) {
    return RouteInformation(uri: Uri.parse(configuration as String));
  }
}

/// 内部包装类，用于在 Tab 切换时保持页面状态。
class _KeepAliveWrapper extends StatefulWidget {
  final Widget child;
  const _KeepAliveWrapper({required this.child});

  @override
  State<_KeepAliveWrapper> createState() => _KeepAliveWrapperState();
}

class _KeepAliveWrapperState extends State<_KeepAliveWrapper> with AutomaticKeepAliveClientMixin {
  @override
  bool get wantKeepAlive => true;

  @override
  Widget build(BuildContext context) {
    super.build(context);
    return widget.child;
  }
}
