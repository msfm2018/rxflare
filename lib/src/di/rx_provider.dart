

import 'package:flutter/material.dart';

import 'rx_di.dart';

/// Widget-scoped dependency provider.
///
/// Automatically registers a dependency when inserted
/// into the widget tree and removes it when disposed.
class RxProvider<T> extends StatefulWidget {
  final T dependency;
  final String? name;
  final Widget child;

  const RxProvider({
    super.key,
    required this.dependency,
    this.name,
    required this.child,
  });

  @override
  State<RxProvider<T>> createState() => _RxProviderState<T>();
}

class _RxProviderState<T> extends State<RxProvider<T>> {
  @override
  void initState() {
    super.initState();
    RxDI.put<T>(widget.dependency, name: widget.name);
  }

  @override
  void dispose() {
    RxDI.delete<T>(name: widget.name);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => widget.child;
}
