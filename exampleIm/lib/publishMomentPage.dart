

import 'package:flutter/material.dart';
import 'package:rxflare/rxflare.dart';

import 'chat_service.dart';

class PublishMomentPage extends StatefulWidget {
  const PublishMomentPage({super.key});

  @override
  State<PublishMomentPage> createState() => _PublishMomentPageState();
}

class _PublishMomentPageState extends State<PublishMomentPage> {
  final TextEditingController _textController = TextEditingController();
  // 模拟已选择的图片列表（实际开发中这里存 File 路径）
  final List<String> _selectedImages = [];

  void _handlePost() {
    if (_textController.text.trim().isEmpty && _selectedImages.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("说点什么吧...")));
      return;
    }

    final chat = RxGet.find<ChatService>();
    // 调用 Service 的发布方法
    chat.postMoment(_textController.text, _selectedImages);
    
    Navigator.pop(context); // 发布成功后返回
  }

  // 模拟添加图片
  void _pickImage() {
    setState(() {
      // 随机取一张占位图模拟选择
      _selectedImages.add("https://picsum.photos/200/200?random=${_selectedImages.length}");
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text("取消", style: TextStyle(color: Colors.black, fontSize: 16)),
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.all(10.0),
            child: ElevatedButton(
              onPressed: _handlePost,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF07C160),
                elevation: 0,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
              ),
              child: const Text("发表", style: TextStyle(color: Colors.white)),
            ),
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          children: [
            // 文本输入区
            TextField(
              controller: _textController,
              maxLines: 5,
              decoration: const InputDecoration(
                hintText: "这一刻的想法...",
                border: InputBorder.none,
              ),
            ),
            const SizedBox(height: 20),
            // 图片预览区 (九宫格布局)
            _buildImagePickerGrid(),
          ],
        ),
      ),
    );
  }

  Widget _buildImagePickerGrid() {
    return Wrap(
      spacing: 10,
      runSpacing: 10,
      children: [
        // 已选图片预览
        ..._selectedImages.map((url) => Stack(
          children: [
            Container(
              width: 80, height: 80,
              decoration: BoxDecoration(
                image: DecorationImage(image: NetworkImage(url), fit: BoxFit.cover),
                borderRadius: BorderRadius.circular(4),
              ),
            ),
            Positioned(
              right: 0, top: 0,
              child: GestureDetector(
                onTap: () => setState(() => _selectedImages.remove(url)),
                child: Container(color: Colors.black54, child: const Icon(Icons.close, size: 16, color: Colors.white)),
              ),
            ),
          ],
        )),
        // “+” 号按钮
        if (_selectedImages.length < 9)
          GestureDetector(
            onTap: _pickImage,
            child: Container(
              width: 80, height: 80,
              color: Colors.grey[100],
              child: const Icon(Icons.add, color: Colors.grey, size: 40),
            ),
          ),
      ],
    );
  }
}