# Dependency Injection Guide

## Simple singleton registration

```dart
class UserController {
  final count = 0.obs;
}

RxDI.put(UserController());
final controller = RxDI.find<UserController>();
```

## Lazy registration

```dart
RxDI.lazyPut<ApiService>(() => ApiService());
final service = RxDI.find<ApiService>();
```

## Multi-instance usage

```dart
RxDI.put(Counter(), name: 'a');
RxDI.put(Counter(), name: 'b');
```

## Provider-based UI patterns

```dart
RxProvider<UserController>(
  dependency: UserController(),
  child: const SomeWidget(),
);
```
