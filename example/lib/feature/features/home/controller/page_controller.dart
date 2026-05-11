import 'package:flutter/material.dart';
import 'package:rxflare/rxflare.dart';
import '../models/user_model.dart';

// 模板二：分页加载 + 下拉刷新 + 上拉更多
class PageControllerv {
  final isLoading = false.obs;
  final isLoadingMore = false.obs;

  final userList = <UserModel>[].obs;
  final currentPage = 1.obs;
  final pageSize = 10.obs;
  final hasMore = true.obs;

  late final userFuture = RxFuture((cancelToken) => fetchList(page: 1));

  Future<List<UserModel>> fetchList({required int page}) async {
    isLoading.value = page == 1;
    try {
      await Future.delayed(const Duration(seconds: 1));
      // 模拟 50 条总数据
      final allData = List.generate(50, (index) => {"id": index + 1, "name": "用户${index + 1}", "age": 18 + index % 20});

      final start = (page - 1) * pageSize.value;
      final end = start + pageSize.value;
      final slice = allData.sublist(start, end.clamp(0, allData.length));
      final list = slice.map(UserModel.fromMap).toList();

      if (page == 1) {
        userList.value = list;
      } else {
        userList.value = [...userList.value, ...list];
      }

      hasMore.value = end < allData.length;
      currentPage.value = page;
      return list;
    } finally {
      isLoading.value = false;
    }
  }

  // 下拉刷新
  Future<void> onRefresh() async {
    currentPage.value = 1;
    hasMore.value = true;
    userFuture.refresh();
  }

  // 上拉加载更多
  Future<void> loadMore() async {
    if (isLoadingMore.value || !hasMore.value) return;
    isLoadingMore.value = true;
    try {
      await fetchList(page: currentPage.value + 1);
    } finally {
      isLoadingMore.value = false;
    }
  }

  void dispose() {
    userFuture.dispose();
    userList.dispose();
  }
}

class HomePagedView extends StatefulWidget {
  const HomePagedView({super.key});

  @override
  State<HomePagedView> createState() => _HomePagedViewState();
}

class _HomePagedViewState extends State<HomePagedView> {
  late PageControllerv c;

  @override
  void initState() {
    super.initState();
    // 对应 RxParent 注入的名称
    c = RxObjMgr.find<PageControllerv>();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("分页加载示例")),
      body: Rx(() {
        // 1. 首屏大 loading
        if (c.userFuture.isLoading && c.userList.value.isEmpty) {
          return const Center(child: CircularProgressIndicator());
        }

        // 2. 错误处理
        if (c.userFuture.hasError && c.userList.value.isEmpty) {
          return Center(
            child: ElevatedButton(onPressed: () => c.userFuture.retry(), child: Text("加载失败: ${c.userFuture.error}\n点击重试")),
          );
        }

        final list = c.userList.value;
        if (list.isEmpty) return const Center(child: Text("空空如也"));

        // 3. 下拉刷新组件
        return RefreshIndicator(
          onRefresh: c.onRefresh,
          child: NotificationListener<ScrollNotification>(
            onNotification: (ScrollNotification scrollInfo) {
              // 滚动到距离底部 100 像素时预加载
              if (scrollInfo.metrics.pixels >= scrollInfo.metrics.maxScrollExtent - 100) {
                c.loadMore();
              }
              return false;
            },
            child: ListView.builder(
              padding: const EdgeInsets.only(bottom: 20),
              itemCount: list.length + 1, // +1 用于显示底部的加载状态
              itemBuilder: (ctx, idx) {
                // 如果是最后一行，显示加载状态或没有更多的提示
                if (idx == list.length) {
                  return _buildFooter();
                }

                // 普通列表项，依然使用 Rx 包裹实现局部年龄更新
                return Rx(() {
                  final user = c.userList.value[idx];
                  return ListTile(
                    leading: CircleAvatar(child: Text("${user.id}")),
                    title: Text(user.name),
                    subtitle: Text("年龄: ${user.age}"),
                    trailing: const Icon(Icons.chevron_right),
                  );
                });
              },
            ),
          ),
        );
      }),
    );
  }

  // 构建底部加载指示器
  Widget _buildFooter() {
    return Rx(() {
      if (c.isLoadingMore.value) {
        return const Padding(
          padding: EdgeInsets.all(16.0),
          child: Center(child: CircularProgressIndicator(strokeWidth: 2)),
        );
      }
      if (!c.hasMore.value) {
        return const Padding(
          padding: EdgeInsets.all(16.0),
          child: Center(
            child: Text("没有更多数据了", style: TextStyle(color: Colors.grey)),
          ),
        );
      }
      return const SizedBox.shrink();
    });
  }
}

// 分页展示页面
class HomeP extends StatelessWidget {
  const HomeP({super.key});

  @override
  Widget build(BuildContext context) {
    return RxParent<PageControllerv>(dependency: PageControllerv(), child: const HomePagedView());
  }
}
