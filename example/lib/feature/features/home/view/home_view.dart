// // features/home/view/home_view.dart
// import 'package:flutter/material.dart';
// import 'package:rxflare/rxflare.dart';

// import '../controller/home_controller.dart';

// class HomeView extends StatefulWidget {
//   const HomeView({super.key});
//   @override
//   State<HomeView> createState() => _HomeViewState();
// }

// class _HomeViewState extends State<HomeView> {
//   late HomeController c;

//   @override
//   void initState() {
//     super.initState();
//     c = RxObjMgr.find<HomeController>(name: "home");

//     // listenState 的作用是：当 RxFuture 内部状态发生变化（loading → done → error）时，通知外部。
//     c.userFuture.listenState(() {
//       print("RxFuture 状态变化 → ${c.userFuture.isInitialLoading ? '加载中' : '完成'}");
//       // if (mounted) setState(() {});
//     });
//   }

//   @override
//   void dispose() {
//     c.dispose();
//     RxObjMgr.delete<HomeController>(name: "home");
//     super.dispose();
//   }

//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       appBar: AppBar(title: const Text("RxFlare 最佳实践")),
//       body: Center(
//         child: Column(
//           mainAxisAlignment: MainAxisAlignment.center,
//           children: [
//             Rx(() => Text("计数: ${c.count.value}", style: const TextStyle(fontSize: 24))),

//             //     Rx(() => Text("姓名: ${c.user.getItem('name')}")),
//             //     Rx(() => Text("是否成年: ${c.isAdult.value ? '是' : '否'}")),

//             //     // if (c.userFuture.isInitialLoading) const CircularProgressIndicator() else if (c.userFuture.hasData) Text("异步数据: ${c.userFuture.data?['name']}"),

//             //  Rx(() {
//             //       if (c.userFuture.isInitialLoading) {
//             //         return const CircularProgressIndicator();
//             //       }
//             //       if (c.userFuture.hasError) {
//             //         return Text("加载失败: ${c.userFuture.error}");
//             //       }
//             //       return Text("异步数据: ${c.userFuture.data?['name'] ?? '无数据'}");
//             //     }),
//             Rx(() {
//               if (c.userFuture.isInitialLoading) {
//                 return const CircularProgressIndicator();
//               }

//               if (c.userList.value.isEmpty) {
//                 return const Text("暂无数据");
//               }

//               return ListView.builder(
//                 shrinkWrap: true,
//                 itemCount: c.userList.value.length,
//                 itemBuilder: (context, index) {
//                   final user = c.userList.getItem(index); // 或 c.userList.value[index]
//                   final isSelected = c.selectedIndex.value == index;

//                   return ListTile(
//                     title: Text(user['name'] ?? ''),
//                     subtitle: Text("年龄: ${user['age']}"),
//                     tileColor: isSelected ? Colors.orange[100] : null,
//                     onTap: () => c.selectUser(index),
//                     trailing: Text((user['age'] as num? ?? 0) >= 18 ? "成年" : "未成年", style: TextStyle(color: Colors.green)),
//                   );
//                 },
//               );
//             }),
//           ],
//         ),
//       ),
//       floatingActionButton: FloatingActionButton(onPressed: c.increment, child: const Icon(Icons.add)),
//     );
//   }
// }

// features/home/view/home_view.dart
import 'package:flutter/material.dart';
import 'package:rxflare/rxflare.dart';
import '../controller/home_controller.dart';

class HomeView extends StatefulWidget {
  const HomeView({super.key});

  @override
  State<HomeView> createState() => _HomeViewState();
}

class _HomeViewState extends State<HomeView> {
  late HomeController c;

  @override
  void initState() {
    super.initState();
    c = RxObjMgr.find<HomeController>(name: "home");

    c.userFuture.listenState(() {
      print("用户列表加载状态变化: ${c.userFuture.isInitialLoading ? '加载中' : '完成'}");
    });
  }

  @override
  void dispose() {
    c.dispose();
    RxObjMgr.delete<HomeController>(name: "home");
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("UserModel 重构示例")),
      body: Center(
        child: Column(
          children: [
            Rx(() => Text("计数: ${c.count.value}", style: const TextStyle(fontSize: 24))),

            // 用户列表
            Expanded(
              child: Rx(() {
                if (c.userFuture.isInitialLoading) {
                  return const Center(child: CircularProgressIndicator());
                }

                if (c.userList.value.isEmpty) {
                  return const Center(child: Text("暂无用户数据"));
                }

                return ListView.builder(
                  itemCount: c.userList.value.length,
                  itemBuilder: (context, index) {
                    final user = c.userList.value[index];
                    final isSelected = c.selectedIndex.value == index;

                    return ListTile(
                      leading: CircleAvatar(
                        child: Text(user.name[0]),
                      ),
                      title: Text(user.name),
                      subtitle: Text("年龄: ${user.age}"),
                      tileColor: isSelected ? Colors.orange[100] : null,
                      onTap: () => c.selectUser(index),
                      trailing: Text(
                        user.age >= 18 ? "✅ 成年" : "未成年",
                        style: TextStyle(
                          color: user.age >= 18 ? Colors.green : Colors.grey,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    );
                  },
                );
              }),
            ),

            Rx(() => Text(
                  "选中用户是否成年: ${c.selectedUserIsAdult.value ? '是' : '否'}",
                  style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                )),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: c.increment,
        child: const Icon(Icons.add),
      ),
    );
  }
}

// // features/home/view/home_view.dart
// import 'package:flutter/material.dart';
// import 'package:rxflare/rxflare.dart';
// import '../controller/home_controller.dart';

// class HomeView extends StatefulWidget {
//   const HomeView({super.key});
//   @override
//   State<HomeView> createState() => _HomeViewState();
// }

// class _HomeViewState extends State<HomeView> {
//   late HomeController c;
//   final ScrollController _scrollController = ScrollController();

//   @override
//   void initState() {
//     super.initState();
//     c = RxObjMgr.find<HomeController>(name: "home");

//     // 监听滚动到底部自动加载更多
//     _scrollController.addListener(_onScroll);

//     c.userFuture.listenState(() {
//       print("用户列表状态变化 → ${c.isLoading.value ? '加载中' : '完成'}");
//     });
//   }

//   void _onScroll() {
//     if (_scrollController.position.pixels >=
//         _scrollController.position.maxScrollExtent - 100) {
//       c.loadMore();
//     }
//   }

//   @override
//   void dispose() {
//     _scrollController.dispose();
//     c.dispose();
//     RxObjMgr.delete<HomeController>(name: "home");
//     super.dispose();
//   }

//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       appBar: AppBar(
//         title: const Text("用户列表 - 分页加载"),
//         actions: [
//           IconButton(
//             icon: const Icon(Icons.refresh),
//             onPressed: c.refresh,
//           ),
//         ],
//       ),
//       body: RefreshIndicator(
//         onRefresh: c.refresh,
//         child: Rx(() {
//           if (c.userFuture.isInitialLoading && c.userList.value.isEmpty) {
//             return const Center(child: CircularProgressIndicator());
//           }

//           return ListView.builder(
//             controller: _scrollController,
//             padding: const EdgeInsets.all(8),
//             itemCount: c.userList.value.length + 1, // +1 用于加载更多指示器
//             itemBuilder: (context, index) {
//               // 加载更多指示器
//               if (index == c.userList.value.length) {
//                 return Center(
//                   child: Padding(
//                     padding: const EdgeInsets.all(16),
//                     child: c.isLoadingMore.value
//                         ? const CircularProgressIndicator()
//                         : c.hasMore.value
//                             ? const Text("上拉加载更多")
//                             : const Text("已经到底啦", style: TextStyle(color: Colors.grey)),
//                   ),
//                 );
//               }

//               final user = c.userList.value[index];
//               final isSelected = c.selectedIndex.value == index;

//               return Card(
//                 color: isSelected ? Colors.orange[50] : null,
//                 child: ListTile(
//                   leading: CircleAvatar(child: Text(user.name[0])),
//                   title: Text(user.name),
//                   subtitle: Text("年龄: ${user.age}  |  ID: ${user.id}"),
//                   trailing: Text(
//                     user.age >= 18 ? "✅ 成年" : "未成年",
//                     style: TextStyle(
//                       color: user.age >= 18 ? Colors.green : Colors.orange,
//                       fontWeight: FontWeight.bold,
//                     ),
//                   ),
//                   onTap: () => c.selectUser(index),
//                 ),
//               );
//             },
//           );
//         }),
//       ),
//       floatingActionButton: FloatingActionButton(
//         onPressed: c.increment,
//         child: const Icon(Icons.add),
//       ),
//     );
//   }
// }