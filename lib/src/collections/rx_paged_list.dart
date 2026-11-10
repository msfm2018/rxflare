import 'dart:async';
import 'dart:collection';

import '../core/rx_state.dart';
import '../rx_router/rx_stack.dart';
import '../utils/rx_debug.dart';

/// 一页数据的加载结果。
class PageResult<T> {
  /// 本页数据（长度应 <= pageSize）。
  final List<T> items;

  /// 总条数。后端能给出总数时传入（例如数据库 COUNT）。
  /// 为 null 表示"无限滚动"模式：靠 [hasMore] 或"本页是否写满"判断是否还有下一页。
  final int? totalCount;

  /// 仅无限滚动模式使用。为 null 时按 `items.length >= pageSize` 推断。
  final bool? hasMore;

  const PageResult(this.items, {this.totalCount, this.hasMore});
}

/// 分页加载函数。[page] 从 0 开始。
typedef PageLoader<T> = Future<PageResult<T>> Function(int page, int pageSize);

/// 某个下标当前的状态。
enum RxPageStatus { loaded, loading, error }

/// 面向超大数据集的响应式分页列表。
///
/// 设计要点：
/// - 继承 `RxState<int>`，value 只是"条数"，数据放在内部页缓存里，
///   所以不会有整表复制、整表 deepEquals。
/// - `list[i]` 注册字段级依赖（和 RxList 一致）：页没加载时返回 null 并自动触发加载，
///   页加载完成后只通知"正在被监听的那些下标"，其他行不重建。
/// - 页缓存按 LRU 淘汰，但**不会淘汰仍被 Rx 监听的页**。
/// - 同一页只会有一个请求（去重）；并发数受 [maxConcurrent] 限制；
///   快速滚动时已滚走、没有监听者的排队请求会被丢弃。
/// - [invalidate] 之后，旧请求的结果会被丢弃（generation 机制）。
///
/// 用法：
/// ```dart
/// final list = RxPagedList<User>(loader: (page, size) async {
///   final r = await api.users(page: page, size: size);
///   return PageResult(r.items, totalCount: r.total);
/// });
///
/// Rx(() => ListView.builder(
///   itemCount: list.length,            // 只依赖总数
///   itemExtent: 64,
///   itemBuilder: (_, i) => Rx(() {     // 每行自己的 Rx：只依赖第 i 项
///     final user = list[i];
///     return user == null ? const Skeleton() : UserTile(user);
///   }),
/// ));
/// ```
///
/// 注意：`list[i]` 必须在每行自己的 `Rx` 里读取，不要在外层 Rx 里读。
class RxPagedList<T> extends RxState<int> {
  RxPagedList({
    required PageLoader<T> loader,
    this.pageSize = 50,
    this.maxCachedPages = 20,
    this.prefetch = 1,
    this.maxConcurrent = 2,
    int? initialTotalCount,
    bool autoLoadFirstPage = true,
    super.name,
  })  : assert(pageSize > 0),
        assert(maxCachedPages > 0),
        assert(maxConcurrent > 0),
        _loader = loader,
        _totalKnown = initialTotalCount != null,
        _knownLength = initialTotalCount ?? 0,
        super(initialTotalCount ?? 1) {
    if (autoLoadFirstPage) _ensure(0, force: true);
  }

  /// 每页条数。
  final int pageSize;

  /// 最多缓存的页数。应大于"屏幕可见页数 + 预取页数"，否则会频繁重新加载。
  final int maxCachedPages;

  /// 向前/向后预取的页数（0 关闭）。
  final int prefetch;

  /// 同时进行的最大请求数。
  final int maxConcurrent;

  final PageLoader<T> _loader;

  // 页缓存：Map 字面量是 LinkedHashMap，插入顺序即 LRU 顺序（最旧在前）。
  final Map<int, List<T>> _cache = {};
  final Set<int> _pending = {}; // 排队中 + 加载中
  final Set<int> _forced = {}; // 显式请求的页，不会被"无关页丢弃"规则丢掉
  final Map<int, Object> _errors = {};
  final Map<int, List<Completer<void>>> _waiters = {};
  final ListQueue<int> _queue = ListQueue<int>();

  /// 我们自己镜像一份"谁在监听哪些下标"，因为 RxState 的 _fieldListeners 是私有的。
  final Map<dynamic, Set<void Function(dynamic)>> _watched = {};

  int _generation = 0;
  int _active = 0;
  bool _pumpScheduled = false;

  bool _totalKnown;
  int _knownLength;
  bool _hasMore = true;

  // ======================
  // 对外 API
  // ======================

  /// 总条数（响应式：在 Rx 中读取会订阅"条数变化"）。
  /// 无限滚动模式下，在还有下一页时会多返回 1（哨兵行，用于触发下一页加载）。
  int get length => value;

  /// 同 [length]，但不注册依赖，可在 Rx 之外安全读取。
  int get peekLength => rawValue;

  /// 当前缓存的页号（从旧到新），主要用于调试和测试。
  List<int> get cachedPages => _cache.keys.toList();

  /// 是否还有更多数据（仅无限滚动模式有意义）。
  bool get hasMore => _totalKnown ? true : _hasMore;

  /// 读取第 [index] 项。注册字段级依赖；页未加载时返回 null 并触发加载。
  T? operator [](int index) {
    final page = _pageFor(index);
    if (page == null) return null;
    final off = index % pageSize;
    return off < page.length ? page[off] : null;
  }

  /// 第 [index] 项的状态（同样注册字段级依赖）。用于区分"加载中"和"失败"。
  RxPageStatus statusAt(int index) {
    final page = _pageFor(index);
    if (page != null) return RxPageStatus.loaded;
    if (index >= 0 && _errors.containsKey(index ~/ pageSize)) {
      return RxPageStatus.error;
    }
    return RxPageStatus.loading;
  }

  /// 第 [index] 项所在页的加载错误（没有则为 null）。
  Object? errorAt(int index) => index < 0 ? null : _errors[index ~/ pageSize];

  /// 读取第 [index] 项，但不注册依赖、不触发加载。
  T? peek(int index) {
    if (index < 0) return null;
    final page = _cache[index ~/ pageSize];
    if (page == null) return null;
    final off = index % pageSize;
    return off < page.length ? page[off] : null;
  }

  /// 修改已缓存的第 [index] 项，只通知监听该下标的 Rx。
  /// 若该页不在缓存中返回 false（请自行写回后端，再 [invalidate] 或重新加载）。
  bool updateAt(int index, T item) {
    if (isDisposed || index < 0) return false;
    final pageNo = index ~/ pageSize;
    final page = _cache[pageNo];
    if (page == null) return false;
    final off = index - pageNo * pageSize;
    if (off >= page.length) return false;
    page[off] = item;
    notifyField(index);
    return true;
  }

  /// 确保第 [index] 项所在页已加载（成功或失败都会完成；失败时请看 [errorAt]）。
  Future<void> ensureLoaded(int index) {
    if (isDisposed || index < 0) return Future<void>.value();
    final pageNo = index ~/ pageSize;
    if (_cache.containsKey(pageNo)) return Future<void>.value();
    final c = Completer<void>();
    (_waiters[pageNo] ??= []).add(c);
    _ensure(pageNo, force: true);
    return c.future;
  }

  /// 重试失败的页。
  Future<void> retryPage(int page) {
    if (isDisposed || page < 0) return Future<void>.value();
    _errors.remove(page);
    _notifyRange(page * pageSize, (page + 1) * pageSize); // 让行从"错误"切回"加载中"
    return ensureLoaded(page * pageSize);
  }

  /// 清空缓存并重新加载（下拉刷新、筛选条件变化时调用）。
  /// 已发出的旧请求结果会被丢弃。返回的 Future 在第 0 页加载结束后完成。
  Future<void> invalidate() {
    if (isDisposed) return Future<void>.value();

    _generation++;
    _completeAllWaiters();
    _cache.clear();
    _pending.clear();
    _forced.clear();
    _queue.clear();
    _errors.clear();
    _active = 0;

    if (!_totalKnown) {
      _knownLength = 0;
      _hasMore = true;
      _syncLength();
    }

    final first = ensureLoaded(0);
    _notifyAllWatched(); // 让可见行重建并重新请求自己需要的页
    refresh(); // 全局通知（条数等）
    return first;
  }

  // ======================
  // 监听镜像（覆盖 RxState 的公开方法）
  // ======================

  @override
  void addFieldListener(dynamic field, void Function(dynamic) listener) {
    if (isDisposed) return;
    (_watched[field] ??= {}).add(listener);
    super.addFieldListener(field, listener);
  }

  @override
  void removeFieldListener(dynamic field, void Function(dynamic) listener) {
    final set = _watched[field];
    if (set != null) {
      set.remove(listener);
      if (set.isEmpty) _watched.remove(field);
    }
    super.removeFieldListener(field, listener);
  }

  // ======================
  // 内部实现
  // ======================

  List<T>? _pageFor(int index) {
    RxStack.registerField(this, index);
    if (isDisposed || index < 0) return null;

    final pageNo = index ~/ pageSize;
    final cached = _cache.remove(pageNo);
    if (cached != null) {
      _cache[pageNo] = cached; // 移到队尾 = 最近使用
      _prefetchAround(pageNo, index - pageNo * pageSize);
      return cached;
    }
    _ensure(pageNo);
    return null;
  }

  void _prefetchAround(int pageNo, int offset) {
    if (prefetch <= 0) return;
    final q = pageSize ~/ 4 < 1 ? 1 : pageSize ~/ 4;
    if (offset >= pageSize - q) {
      for (var k = 1; k <= prefetch; k++) {
        _ensure(pageNo + k);
      }
    }
    if (offset < q) {
      for (var k = 1; k <= prefetch; k++) {
        _ensure(pageNo - k);
      }
    }
  }

  bool _inRange(int start) {
    if (start == 0) return true;
    if (start < _knownLength) return true;
    return !_totalKnown && _hasMore && start == _knownLength;
  }

  /// 登记一个页加载请求。只做登记，不会同步调用 loader（避免在 build 期间发请求）。
  void _ensure(int pageNo, {bool force = false}) {
    if (isDisposed || pageNo < 0) return;
    if (_cache.containsKey(pageNo) || _pending.contains(pageNo)) return;
    if (!force) {
      if (_errors.containsKey(pageNo)) return; // 失败的页只能手动 retryPage
      if (!_inRange(pageNo * pageSize)) return;
    }
    _pending.add(pageNo);
    if (force) _forced.add(pageNo);
    _queue.addFirst(pageNo); // 后进先出：最新的滚动位置优先加载
    _schedulePump();
  }

  void _schedulePump() {
    if (_pumpScheduled) return;
    _pumpScheduled = true;
    scheduleMicrotask(() {
      _pumpScheduled = false;
      _pump();
    });
  }

  void _pump() {
    if (isDisposed) return;
    while (_active < maxConcurrent && _queue.isNotEmpty) {
      final pageNo = _queue.removeFirst();
      if (!_forced.contains(pageNo) && !_isRelevant(pageNo)) {
        _pending.remove(pageNo); // 已经滚走了，不再需要
        continue;
      }
      _active++;
      unawaited(_load(pageNo));
    }
  }

  /// 没有任何监听者时一律视为相关；否则只有"监听下标所在页及其预取邻页"相关。
  bool _isRelevant(int pageNo) {
    if (_watched.isEmpty) return true;
    for (final k in _watched.keys) {
      if (k is! int) continue;
      final p = k ~/ pageSize;
      if (pageNo >= p - prefetch && pageNo <= p + prefetch) return true;
    }
    return false;
  }

  Future<void> _load(int pageNo) async {
    final gen = _generation;
    PageResult<T>? result;
    Object? error;

    try {
      result = await _loader(pageNo, pageSize);
    } catch (e) {
      error = e;
    }

    // 已 invalidate 或已 dispose：丢弃结果，也不要动新一代的计数
    if (isDisposed || gen != _generation) return;

    _active--;
    _pending.remove(pageNo);
    _forced.remove(pageNo);

    if (result != null) {
      _errors.remove(pageNo);
      _apply(pageNo, result);
    } else {
      _errors[pageNo] = error!;
      RxDebug.log('RxPagedList page $pageNo failed: $error');
    }

    _notifyRange(pageNo * pageSize, (pageNo + 1) * pageSize);
    _completeWaiters(pageNo);
    _pump();
  }

  void _apply(int pageNo, PageResult<T> res) {
    final start = pageNo * pageSize;
    final items = List<T>.of(res.items);
    _cache[pageNo] = items;

    if (res.totalCount != null) {
      _totalKnown = true;
      _knownLength = res.totalCount!;
    } else {
      final loadedEnd = start + items.length;
      if (loadedEnd > _knownLength) _knownLength = loadedEnd;
      if (loadedEnd >= _knownLength) {
        _hasMore = res.hasMore ?? items.length >= pageSize;
      }
    }

    _syncLength();
    _evict(keep: pageNo);
  }

  void _syncLength() {
    final len = _totalKnown ? _knownLength : _knownLength + (_hasMore ? 1 : 0);
    if (len != rawValue) value = len; // 变化时通知全局监听者（如 itemCount）
  }

  /// LRU 淘汰：从最旧的开始，跳过刚加载的页和仍被监听的页。
  void _evict({required int keep}) {
    if (_cache.length <= maxCachedPages) return;

    final watchedPages = <int>{
      for (final k in _watched.keys)
        if (k is int) k ~/ pageSize,
    };

    for (final pageNo in _cache.keys.toList()) {
      if (_cache.length <= maxCachedPages) break;
      if (pageNo == keep || watchedPages.contains(pageNo)) continue;
      _cache.remove(pageNo);
    }
  }

  void _notifyRange(int start, int end) {
    if (_watched.isEmpty) return;
    final hits = <int>[
      for (final k in _watched.keys)
        if (k is int && k >= start && k < end) k,
    ];
    for (final i in hits) {
      notifyField(i);
    }
  }

  void _notifyAllWatched() {
    for (final k in _watched.keys.toList()) {
      notifyField(k);
    }
  }

  void _completeWaiters(int pageNo) {
    final list = _waiters.remove(pageNo);
    if (list == null) return;
    for (final c in list) {
      if (!c.isCompleted) c.complete();
    }
  }

  void _completeAllWaiters() {
    for (final list in _waiters.values) {
      for (final c in list) {
        if (!c.isCompleted) c.complete();
      }
    }
    _waiters.clear();
  }

  @override
  void dispose() {
    if (isDisposed) return;
    _generation++;
    _completeAllWaiters();
    _cache.clear();
    _pending.clear();
    _forced.clear();
    _errors.clear();
    _queue.clear();
    _watched.clear();
    super.dispose();
  }
}
