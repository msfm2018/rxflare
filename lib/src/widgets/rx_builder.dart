import 'package:flutter/material.dart';

import 'rx.dart';

/// A convenience widget that wraps [Rx] for simple builder patterns.
///
/// This widget is useful when you want to use the `builder` pattern
/// (similar to `Builder` or `AnimatedBuilder`) while benefiting from
/// RxFlare's automatic dependency tracking.
///
/// **Example:**
/// ```dart
/// RxBuilder(
///   builder: (context) {
///     return Text('Count: ${count.value}');
///   },
/// );
/// ```
///
/// It is especially handy inside lists or when you prefer the classic
/// `WidgetBuilder` signature.
class RxBuilder extends StatelessWidget {
  /// The builder function that returns the widget to be rebuilt reactively.
  final WidgetBuilder builder;

  const RxBuilder({
    super.key,
    required this.builder,
  });

  @override
  Widget build(BuildContext context) {
    return Rx(() => builder(context));
  }
}