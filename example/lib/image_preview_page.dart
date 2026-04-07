

import 'package:flutter/material.dart';

class ImagePreviewPage extends StatelessWidget {
  final String url;
  final Object heroTag;

  const ImagePreviewPage({super.key, required this.url, required this.heroTag});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => Navigator.pop(context), // 点击任意位置返回
      child: Scaffold(
        backgroundColor: Colors.black, // 黑色背景
        body: Center(
          child: Hero(
            tag: heroTag, // 这里的 tag 必须与列表页一致
            child: Image.network(
              url,
              fit: BoxFit.contain,
              width: MediaQuery.of(context).size.width,
            ),
          ),
        ),
      ),
    );
  }
}