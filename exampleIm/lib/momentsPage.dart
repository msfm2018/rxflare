import 'package:flutter/material.dart';
import 'package:rxflare/rxflare.dart';
import 'chat_service.dart';

class MomentsPage extends StatelessWidget {
  const MomentsPage({super.key});

  @override
  Widget build(BuildContext context) {
    final service = RxGet.find<ChatService>();

    return Scaffold(
      body: CustomScrollView(
        slivers: [
          // 1. 顶部背景与头像
          SliverToBoxAdapter(
            child: SizedBox(
              height: 300,
              child: Stack(
                clipBehavior: Clip.none,
                children: [
                  Container(color: Colors.grey[300], height: 260, width: double.infinity, child: const Center(child: Text("背景图"))),
                  Positioned(
                    right: 20,
                    bottom: 10,
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        const Text("我的名字", style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold, shadows: [Shadow(blurRadius: 2)])),
                        const SizedBox(width: 10),
                        Container(width: 70, height: 70, decoration: BoxDecoration(color: Colors.orange, borderRadius: BorderRadius.circular(8))),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
          // 2. 动态列表
          RxObserver(
            () => SliverList(
              delegate: SliverChildBuilderDelegate(
                (context, index) {
                  final item = service.momentsList.value[index];
                  return _buildMomentItem(service, item);
                },
                childCount: service.momentsList.value.length,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMomentItem(ChatService service, Map item) {
    return Padding(
      padding: const EdgeInsets.all(15.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 头像
          Container(
            width: 45, height: 45,
            decoration: BoxDecoration(color: item["avatarColor"], borderRadius: BorderRadius.circular(5)),
            child: Center(child: Text(item["avatar"], style: const TextStyle(color: Colors.white))),
          ),
          const SizedBox(width: 10),
          // 内容区
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(item["userName"], style: const TextStyle(color: Color(0xFF576B95), fontWeight: FontWeight.bold, fontSize: 16)),
                const SizedBox(height: 5),
                Text(item["content"], style: const TextStyle(fontSize: 15, height: 1.4)),
                NineGridView(images: List<String>.from(item["images"])),
                const SizedBox(height: 10),
                // 底部操作栏
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text("1小时前", style: TextStyle(color: Colors.grey[500], fontSize: 13)),
                    IconButton(icon: const Icon(Icons.more_horiz, color: Color(0xFF576B95)), onPressed: () {}),
                  ],
                ),
                // 点赞与评论区
                if (item["likes"].isNotEmpty || item["comments"].isNotEmpty)
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(color: Colors.grey[100], borderRadius: BorderRadius.circular(4)),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        if (item["likes"].isNotEmpty)
                          Row(
                            children: [
                              const Icon(Icons.favorite_border, size: 14, color: Color(0xFF576B95)),
                              const SizedBox(width: 5),
                              Expanded(child: Text(item["likes"].join(", "), style: const TextStyle(color: Color(0xFF576B95), fontWeight: FontWeight.w500))),
                            ],
                          ),
                        if (item["likes"].isNotEmpty && item["comments"].isNotEmpty) const Divider(),
                        ...item["comments"].map<Widget>((c) => Padding(
                          padding: const EdgeInsets.symmetric(vertical: 2),
                          child: RichText(text: TextSpan(
                            style: const TextStyle(color: Colors.black, fontSize: 14),
                            children: [
                              TextSpan(text: "${c['from']}: ", style: const TextStyle(color: Color(0xFF576B95), fontWeight: FontWeight.bold)),
                              TextSpan(text: c['content']),
                            ]
                          )),
                        )).toList(),
                      ],
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}