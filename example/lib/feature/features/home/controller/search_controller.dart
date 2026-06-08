import 'package:flutter/material.dart';

import 'package:rxflare/rxflare.dart';
import '../models/user_model.dart';
// 搜索防抖（直接用 RxFuture.search 工厂）

class SearchController {
  final keyword = "".obs;
  final searchList = <UserModel>[].obs;

  // 1. 将 keyword 设为依赖，触发 500ms 防抖
  late final searchFuture = RxFuture.search((cancelToken) => search(), dependencies: [keyword]); // 也可以在构造函数传入 dependencies: [keyword]

  Future<List<UserModel>> search() async {
    final kw = keyword.value.trim();
    if (kw.isEmpty) {
      searchList.value = [];
      return [];
    }

    // 模拟网络请求延迟
    await Future.delayed(const Duration(milliseconds: 500));

    final mock = [UserModel(id: 1, name: "张三", age: 20), UserModel(id: 2, name: "李四", age: 25), UserModel(id: 3, name: "张小五", age: 18)];

    final res = mock.where((e) => e.name.contains(kw)).toList();
    searchList.value = res;
    return res;
  }

  void dispose() {
    searchFuture.dispose();
    keyword.dispose();
    searchList.dispose();
  }
}

class SearchView extends StatefulWidget {
  const SearchView({super.key});

  @override
  State<SearchView> createState() => _SearchViewState();
}

class _SearchViewState extends State<SearchView> {
  late SearchController c;
  final TextEditingController _textController = TextEditingController();

  @override
  void initState() {
    super.initState();
    c = RxDI.find<SearchController>();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("搜索防抖 Demo")),
      body: Column(
        children: [
          // 搜索输入框
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: TextField(
              controller: _textController,
              decoration: InputDecoration(
                hintText: "输入姓名搜索 (如: 张)",
                prefixIcon: const Icon(Icons.search),
                suffixIcon: IconButton(
                  icon: const Icon(Icons.clear),
                  onPressed: () {
                    _textController.clear();
                    c.keyword.value = ""; // 清空触发自动搜索
                  },
                ),
                border: const OutlineInputBorder(),
              ),
              // 关键：输入变化时只更新关键字的值
              onChanged: (val) => c.keyword.value = val,
            ),
          ),

          // 结果展示区域
          Expanded(
            child: Rx(() {
              // 1. 如果正在加载（防抖结束后触发的请求）
              if (c.searchFuture.isLoading) {
                return const Center(child: CircularProgressIndicator());
              }

              // 2. 错误处理
              if (c.searchFuture.hasError) {
                return Center(child: Text("搜索出错: ${c.searchFuture.error}"));
              }

              final results = c.searchList.value;

              // 3. 空状态处理
              if (results.isEmpty) {
                return Center(
                  child: Text(c.keyword.value.isEmpty ? "开始输入以搜索" : "未找到相关结果", style: const TextStyle(color: Colors.grey)),
                );
              }

              // 4. 列表展示
              return ListView.builder(
                itemCount: results.length,
                itemBuilder: (ctx, idx) {
                  final user = results[idx];
                  return ListTile(leading: const Icon(Icons.person), title: Text(user.name), subtitle: Text("年龄: ${user.age}"));
                },
              );
            }),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _textController.dispose();
    super.dispose();
  }
}

class SearchPage extends StatelessWidget {
  const SearchPage({super.key});

  @override
  Widget build(BuildContext context) {
    return RxProvider<SearchController>(dependency: SearchController(), child: const SearchView());
  }
}
