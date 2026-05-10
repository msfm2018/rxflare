# Changelog
## [1.4.2] - 2026-05-10

### Added
* 完善例程
* RxAutoDispose 是一个 Mixin，通过 with 方式混入 StatefulWidget，实现资源的自动注册与释放
```
class _UserPageState extends State<UserPage> with RxAutoDispose {
  final count = 0.obs;
  late final RxFuture<User> userFuture;

  @override
  void initState() {
    super.initState();

    userFuture = RxFuture(() async { ... }).autoDispose(this);

    count.listen((v) => print(v)).autoDispose(this);
  }

  @override
  Widget build(BuildContext context) { ... }
}
```
## [1.4.1] - 2026-05-09

### 优化
* 路由注册优化
* 优化 register 路由注册机制
* 移除 path 路径参数，使注册方式更加简洁
* RxFuture 状态监听增强

* 新增 listenState 方法，用于监听 RxFuture 内部状态变化。

* 状态流转包括：

* loading → done
* loading → error
* 其他状态切换

* 适用于在状态变化时主动通知 UI 刷新。

## [1.4.0] - 2026-05-08

### Added

*  集合响应式增强 (RxCollections)：引入了 RxList 、 RxSet、rx_map，旨在通过不可变更新（Immutable Updates）简化集合状态的管理。

* RxList：
* 支持原生 List 语法：可以通过 [] 读取和 []= 修改元素
* 自动化响应：内部在进行 add、removeAt 或 updateAt 操作时，会自动创建新的 List 实例并触发响应式通知。

* 示例：
```
Dart
  final todos = RxList<String>(["Learn Flutter"]);
  todos.add("Build app"); // 自动触发 UI 刷新
  todos[0] = "Master Flutter"; // 运算符重载支持
```

## [1.3.1] - 2026-04-28

### Added

*  引入 RxBuilder 组件：

* 提供了一个标准的 StatelessWidget 包装器，方便在 Widget 树中直接进行响应式局部刷新。


* 示例：
```
Dart
RxBuilder(
  builder: (context) => Text('当前计数: ${count.value}'),
)
```
## [1.3.0] - 2026-04-25

### Added
* 🚀 引入全新响应式路由系统 `RxRouter`：基于 `RxState` 驱动的 Navigator 2.0 路由管理方案。

* 🧭 多栈管理机制：
  * 支持全局根栈（`memPages`）
  * 支持多 Tab 局部栈（`tabPages`）独立并行管理

* ✨ 声明式 + 命令式统一 API：
  * `rxr.to('/path')`
  * `rxr.back()`
  内部自动映射为声明式状态更新

* 🔗 动态路径匹配：
  * 支持 `/user/:id` 形式路径参数
  * 支持完整 URL Query 参数解析

* 🛡️ 路由守卫（Guard）：
  * 在 `RxDef` 中支持异步拦截逻辑
  * 可用于登录校验、权限控制等场景

* 📦 强类型参数传递：
  * 基于 `RxArgs` 实现对象级参数传递
  * 自动生命周期管理与回收

* 🔄 异步结果回传：
  * `to<T>()` 返回 `Future<T?>`
  * 支持 `back(result: ...)` 回传页面结果

* 🌐 Web 适配支持：
  * 提供 `RxRouteParser` 与 `RxRouterDelegate`
  * 支持浏览器地址栏同步
  * 支持手动输入 URL 解析

* 🧩 内置 `KeepAliveWrapper`：
  * 优化 Tab 切换时的页面状态保持

## [1.2.0] - 2026-04-18
### Added
* 新增泛型扩展 `RxAnyExtension<T>`，支持任意对象通过 `.obs` 快速转换为 `RxState<T>`：
  ```dart
  final user = User().obs;
  final count = 1.obs;
  ```
* 统一 .obs 使用方式，减少对基础类型（int、String 等）的重复扩展依赖。

## [1.1.9] - 2026-04-08
* 优化了文档可读性。

## [1.1.8] - 2026-04-07
* 完善了 API 文档注释 (Completed documentation comments).
* 优化了文档可读性。

## [1.1.7] - 2026-04-07
* 修复了示例代码中的错误。

## [1.1.6] - 2026-04-07
* 补全了示例项目 (Full demo project implementation).

## [1.1.5] - 2026-04-05
* 优化了嵌套依赖处理逻辑 (Nested dependency handling):
  ```dart
  RxA(() {
    RxB(() {
      // 嵌套依赖支持
    });
  });
  ```

## [1.1.4] -2026-04-01

* 增加例子 列表字段更新 map字段更新

# Changelog

## [1.1.3] - 2026-03-28
* Fixed analyzer warnings to improve package health.
* Improved type safety in `rx_get`.
* Cleaned up documentation comments for better IDE support.

## [1.1.1] - 2026-03-21
### Changed
* 核心响应式逻辑更新，优化了性能。

## [1.0.0] - 2026-03-18
### Added
* 增加 `listen` 接口，支持对数据变化的监听。
* 正式发布 1.0.0 稳定版。

## [0.0.4] - 2026-03-10
* 修改并优化了示例代码 (Demo)。

## [0.0.3] - 2026-03-05
### Added
* 新增核心响应式组件：`rx_event_simple`, `rx_future`, `RxValue<T>`, `RxStore<T>`, `RxNotifier<T>`。
* 添加了自定义 Demo 演示。

## [0.0.1] - 2025-06-04
* Initial release of rxflare.