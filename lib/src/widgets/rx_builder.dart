import 'package:flutter/material.dart';

import 'rx.dart';


/// 平衡其它系统加一个
class RxBuilder extends StatelessWidget {
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
