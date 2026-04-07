

import 'package:flutter/material.dart';

class EmojiPickerPanel extends StatelessWidget {
  final Function(String) onEmojiSelected;

  EmojiPickerPanel({super.key, required this.onEmojiSelected});

  // 微信常用的表情列表（你可以根据需要添加更多）
  final List<String> emojis = [
    "😀", "😁", "😂", "🤣", "😃", "😄", "😅", "😆", "😉", "😊", "😋", "😎",
    "😍", "😘", "😗", "😙", "😚", "🙂", "🤗", "🤩", "🤔", "🤨", "😐", "😑",
    "😶", "🙄", "😏", "😣", "😥", "😮", "🤐", "😯", "😪", "😫", "😴", "😌"
  ];

  @override
  Widget build(BuildContext context) {
    return Material(
      elevation: 8,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        width: 300,
        height: 200,
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: Colors.grey.shade300),
        ),
        child: GridView.builder(
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 8, // 每行8个表情
            mainAxisSpacing: 5,
            crossAxisSpacing: 5,
          ),
          itemCount: emojis.length,
          itemBuilder: (context, index) {
            return MouseRegion(
              cursor: SystemMouseCursors.click,
              child: GestureDetector(
                onTap: () => onEmojiSelected(emojis[index]),
                child: Center(
                  child: Text(emojis[index], style: const TextStyle(fontSize: 20)),
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}