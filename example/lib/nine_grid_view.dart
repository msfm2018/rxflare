import 'package:flutter/material.dart';

class NineGridView extends StatelessWidget {
  final List<String> images;
  const NineGridView({super.key, required this.images});

  @override
  Widget build(BuildContext context) {
    if (images.isEmpty) return const SizedBox.shrink();

    // 单张图逻辑
    if (images.length == 1) {
      return Padding(
        padding: const EdgeInsets.only(top: 8.0),
        child: Image.network(images[0], width: 200, fit: BoxFit.cover),
      );
    }

    // 多张图使用 GridView
    int crossAxisCount = images.length == 4 ? 2 : 3; // 4张图显示2x2
    double width = images.length == 4 ? 210 : 320; // 简单控制总宽度

    return Container(
      width: width,
      padding: const EdgeInsets.only(top: 8.0),
      child: GridView.builder(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: crossAxisCount,
          crossAxisSpacing: 4,
          mainAxisSpacing: 4,
        ),
        itemCount: images.length,
        itemBuilder: (context, index) => Image.network(images[index], fit: BoxFit.cover),
      ),
    );
  }
}