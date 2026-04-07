
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';

String formatTime(int timestamp) {
  final now = DateTime.now();
  final time = DateTime.fromMillisecondsSinceEpoch(timestamp);

  final diff = now.difference(time);

  // 1️⃣ 刚刚
  if (diff.inMinutes < 1) {
    return "刚刚";
  }

  // 2️⃣ 几分钟前
  if (diff.inMinutes < 60) {
    return "${diff.inMinutes}分钟前";
  }

  // 3️⃣ 今天 → HH:mm
  if (now.day == time.day &&
      now.month == time.month &&
      now.year == time.year) {
    return "${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}";
  }

  // 4️⃣ 昨天
  final yesterday = now.subtract(const Duration(days: 1));
  if (yesterday.day == time.day &&
      yesterday.month == time.month &&
      yesterday.year == time.year) {
    return "昨天";
  }

  // 5️⃣ 更早 → MM/dd
  return "${time.month}/${time.day}";
}



 // 封装一个带缓存的网络头像组件
  Widget buildNetworkAvatar(String url, {double radius = 18}) {
    return CachedNetworkImage(
      imageUrl: url,
      imageBuilder: (context, imageProvider) => CircleAvatar(radius: radius, backgroundImage: imageProvider),
      // 加载时的占位图（转圈圈）
      placeholder: (context, url) => CircleAvatar(
        radius: radius,
        backgroundColor: Colors.grey[300],
        child: const SizedBox(width: 15, height: 15, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white)),
      ),
      // 加载失败显示的图标
      errorWidget: (context, url, error) => CircleAvatar(
        radius: radius,
        backgroundColor: Colors.grey,
        child: const Icon(Icons.error_outline, color: Colors.white, size: 18),
      ),
    );
  }

    // 分类头部（A, B, C 或 星标）
  Widget buildSubHeader(IconData? icon, String title) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 5),
      width: double.infinity,
      child: Row(
        children: [
          if (icon != null) Icon(icon, size: 14, color: Colors.grey),
          const SizedBox(width: 5),
          Text(title, style: const TextStyle(fontSize: 11, color: Colors.grey)),
        ],
      ),
    );
  }
