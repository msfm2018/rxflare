# Changelog

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