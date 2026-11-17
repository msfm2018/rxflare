# RxFlare performance investigation

This document describes how to measure the current implementation; it does not claim benchmark results for the supplied archive.

## First principles

- Use the narrowest dependency that matches the UI: whole-state reads for whole-state views, `RxList[index]` / `RxMap[key]` for row/key-specific views.
- Prefer immutable update methods provided by `RxList`, `RxMap`, and `RxSet`; do not mutate the raw List/Map/Set returned by convenience getters and expect notifications.
- Use `batch(() { ... })` when several synchronous writes should be coalesced. Batching groups notifications; it does not make writes transactional.
- For very large datasets, evaluate `RxPagedList` rather than eagerly retaining all rows in one `RxList`.
- Dispose `RxComputed`, `RxFuture`, effects, watchers, listeners, event tokens, and router delegates according to ownership.

## Measure separately

A useful benchmark suite should isolate at least these dimensions:

| Dimension | What to record | Suggested scenario |
|---|---|---|
| State update latency | elapsed time per update and throughput | repeated scalar writes, field writes, batched writes |
| Widget rebuilds | builder invocation count | update one `RxList` index while multiple rows observe different indexes |
| Collection scaling | time and allocations as collection size grows | index update, bulk update, append/remove |
| Memory | retained heap before/after workload | create/dispose many states, effects, pages, and paged-list rows |
| Lifecycle | create/dispose time and residual listeners | repeated mount/unmount and subscription cancellation |
| Async requests | request count, cancellation, stale-result handling | debounce, retry, polling, concurrent refresh |

Record Flutter/Dart version, OS, device/CPU, build mode, collection size, iteration count, warm-up policy, and whether measurements include widget pumping.

## Existing benchmark caveat

The archive contains `rxflare_core/test/rx_list/rx_list_benchmark.dart`. It measures repeated copying of ordinary Dart Lists for sizes 100, 1,000, 10,000, and 100,000. It does not benchmark `RxList`, listener dispatch, widget rebuilds, memory, or lifecycle. Do not use it as evidence that RxFlare beats another state-management library.

## Rebuild-count test example

The existing `rx_field_rebuild_test.dart` demonstrates the right kind of deterministic test: build separate widgets that read separate indexes, reset counters after the first frame, mutate one index, pump, then assert only the dependent builder ran. Keep correctness tests separate from timing benchmarks.

## Benchmark discipline

- Prefer profile/release mode for timing; debug mode is for correctness and diagnostics.
- Warm up before recording and repeat enough times to avoid single-run noise.
- Report median and spread, not only the best run.
- Compare equivalent workloads and identical runtime conditions.
- Include allocation/GC effects when collection copying is part of the operation.
- Never infer memory behavior from elapsed time alone.
