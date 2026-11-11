# Migration guide: 1.x → 2.0

## Breaking changes

### 1. Package split (monorepo)

RxFlare is now multiple packages:

| Package | Contents |
|---------|----------|
| `rxflare_core` | `.obs`, `RxState`, `computed`, `batch`, `untracked`, `effect`, `watch`, `Rx` widget, collections, DI, event bus, `RxFuture` |
| `rxflare_router` | `RxRouter`, `rxr`, `RxWidgetsApp`, route args / guards |
| `rxflare_i18n` | `RxLocale` |
| `rxflare` | Umbrella — re-exports all of the above (one-line dependency) |

**Most apps can keep:**

```yaml
dependencies:
  rxflare: ^2.0.0
```

If you only need state management:

```yaml
dependencies:
  rxflare_core: ^2.0.0
```

### 2. Removed APIs

| Removed | Replacement |
|---------|-------------|
| `RxObjMgr` | `RxDI` |
| `RxParent` | `RxProvider` |
| `RxMaterialApp` | `RxWidgetsApp` + your own `MaterialApp` / theming (already removed in 1.8.0) |

### 3. `RxStack` location

`RxStack` lives in `rxflare_core` (dependency tracking is not routing). You should not import it from a router path.

### 4. Synchronous refresh (since 1.8.2)

`Rx` uses synchronous `setState` when safe. For multiple writes in one handler:

```dart
batch(() {
  a.value = 1;
  b.value = 2;
});
```

## New APIs in 2.0

### `effect`

```dart
final stop = effect(() {
  print(count.value);
});
// later
stop();
```

### `watch`

```dart
final stop = watch(
  () => count.value,
  (v) => print('count=$v'),
);
```

### `batch` / `untracked` (also in 1.8.3)

See README section "Batch updates & untracked reads".

## Refresh timing

1. **Write outside `batch`**: listeners run immediately (`notifyListenersNow`).
2. **Write inside `batch`**: notifications are queued; flushed once when the outermost `batch` ends.
3. **`Rx` widget refresh**:
   - If not in build/layout/paint → `setState` immediately.
   - If inside build/layout/paint → post-frame callback (avoids "setState during build").
4. **`untracked`**: reads do not register on `RxStack`; no subscription is created.
5. **Field vs global**: `updateField` / index writes notify only field listeners; full `value =` notifies global listeners.

Diamond dependencies in `computed` re-evaluate once per source notification; use `batch` when updating multiple sources together to avoid intermediate frames.
