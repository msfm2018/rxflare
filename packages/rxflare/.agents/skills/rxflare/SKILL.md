---
name: rxflare
description: Use RxFlare 2.0 for reactive state management in Flutter, including RxState, .rx, legacy .obs, computed, effect, watch, batch, reactive collections, RxPagedList, dependency injection, routing, and localization. Consult the bundled references before generating RxFlare code.
---

# RxFlare 2.0

Use this skill when creating, reviewing, debugging, or migrating Flutter code that uses RxFlare 2.0.

## Non-negotiable rules

1. **Use the APIs that exist in this repository version.** The primary value extension is `.rx`. The legacy `.obs` getter remains available but is deprecated. For new code, always use `.rx`. Collection constructors use `.rxList`, `.rxMap`, `.rxSet`, `.rxMapD`, and `.rxListMap`; their `.obsList`, `.obsMap`, `.obsSet`, `.obsMapD`, and `.obsListMap` aliases are deprecated compatibility APIs.
2. Import `package:rxflare/rxflare.dart` for the umbrella package, or import a focused package when the application intentionally depends on only one module:
   - `package:rxflare_core/rxflare_core.dart`
   - `package:rxflare_router/rxflare_router.dart`
   - `package:rxflare_i18n/rxflare_i18n.dart`
3. Read the relevant file under `references/` before using an unfamiliar API.
4. Prefer examples that match the actual public exports and signatures. Do not infer an API from a README snippet if it conflicts with the implementation.
5. Do not silently change public API signatures, package boundaries, notification semantics, or lifecycle behavior while fixing an issue. Explain proposed breaking changes first.
6. RxFlare core widgets and router are designed to avoid a direct Material/Cupertino dependency. Do not add Material or Cupertino imports to `rxflare_core` or `rxflare_router` without a deliberate architecture decision.
7. Use `batch(() { ... })` when several synchronous state writes should be grouped. Do not promise that every dependent computation/effect has identical scheduling semantics; check the relevant implementation.
8. Dispose resources that implement `Disposable`, stop `effect`/`watch` subscriptions, and cancel listeners when their owner is disposed.
9. For large datasets, do not model hundreds of thousands of rows as one eagerly retained `RxList`; evaluate `RxPagedList` and its per-row dependency pattern.
10. When uncertain, state what is not established by the source and ask for the relevant source file or test instead of fabricating behavior.

## Workflow

1. Identify which package owns the API.
2. Read the corresponding reference:
   - State and widgets: `references/state-management.md`
   - Collection APIs: `references/collections.md`
   - Effects and computed values: `references/effect-watch.md`
   - Navigation: `references/routing.md`
   - DI and providers: `references/dependency-injection.md`
   - 1.x migration: `references/migration-v2.md`
3. Check the exported entrypoint (`lib/rxflare*.dart`) before suggesting imports.
4. If behavior matters, inspect or add a focused test. A code sample in documentation is not proof that behavior is tested.
5. Keep changes minimal and preserve existing public API unless the user explicitly approves a redesign.

## Quick start

```dart
import 'package:flutter/material.dart';
import 'package:rxflare/rxflare.dart';

final count = 0.rx;

class Counter extends StatelessWidget {
  const Counter({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Rx(() => Text('Count: ${count.value}')),
        ElevatedButton(
          onPressed: () => count.value++,
          child: const Text('Increment'),
        ),
      ],
    );
  }
}
```

The `.rx` extension returns an `RxState<T>`. `.obs` is deprecated and retained only for source compatibility.

## Package map

| Package | Responsibility |
|---|---|
| `rxflare_core` | `RxState`, `.rx` (legacy `.obs`), computed/effect/watch/batch, widgets, collections, DI, event bus, `RxFuture` |
| `rxflare_router` | `RxRouter`, `rxr`, `RxWidgetsApp`, route/page arguments |
| `rxflare_i18n` | `RxLocale` and String translation extensions |
| `rxflare` | Umbrella package re-exporting core, router, and i18n |

## Known source caveats for this 2.0 snapshot

These are audit findings, not intended API guarantees. Avoid describing them as fixed until the implementation and tests are updated:

- `RxComputed` currently evaluates its compute callback in the superclass initializer and again while initializing dependency tracking.
- `RxList.updateWhere` and `replaceWhere` assign through `value` before field notifications, so global listeners are also notified despite the method comments describing index-scoped notifications.
- `RxList.updateAt` accepts `notifyGlobal`, but the current implementation does not use that parameter.
- `RxState.listen` and `bind` append listeners directly without the disposed guard used by `addListener`.
- `RxEffect` only updates its dependency set after a successful callback run; exception behavior needs an explicit policy and tests.
- `RxWidgetsApp.build` performs router registration/initialization as a build side effect.
- The README example for `RxRoute.builder` uses a one-argument callback, while the current `RxRoute` constructor declares `Widget Function()`.

When asked to fix these, first add regression tests, then make the smallest implementation change. Do not claim the archive was run through Flutter tests unless a Flutter SDK was actually available and the tests were executed.
