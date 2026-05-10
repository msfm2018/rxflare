import 'package:flutter/material.dart';
import 'package:rxflare/rxflare.dart';
import '../models/user_model.dart';



class HomeController {
  // 1. 移除手动 isLoading，直接用 userFuture.isLoading
  final userList = <UserModel>[].obs;
  final selectedIndex = (-1).obs;

  late final userFuture = RxFuture((token) => fetchUserList(token));

  Future<List<UserModel>> fetchUserList(CancelToken? token) async {
    // 模拟网络请求
    await Future.delayed(const Duration(seconds: 1));
    final rawList = [
        {"id": 1, "name": "张三", "age": 17},
        {"id": 2, "name": "李四", "age": 28},
        {"id": 3, "name": "王五", "age": 35},
      ];
    final users = rawList.map(UserModel.fromMap).toList();
    userList.value = users;
    return users;
  }

  void updateUserAge(int index, int newAge) {
    if (index < 0 || index >= userList.value.length) return;
    
    // 2. 使用 updateField 会修改内部值，但必须确保 UI 有在 Rx(()=>...) 中监听 userList.value[index]
    final oldUser = userList.value[index];
    userList.updateField(index, oldUser.copyWith(age: newAge));
    
    // 3. 强制通知 UI 更新（如果 Rx() 没能自动捕获，可以手动触发）
    userList.refresh(); 
  }

  void selectUser(int index) => selectedIndex.value = index;
}


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
    c = RxObjMgr.find<HomeController>(name: "homex");
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("基础列表+局部更新")),
      body: Rx(() {
        // 1. 使用 RxFuture 自带的 isLoading
        if (c.userFuture.isLoading) {
          return const Center(child: CircularProgressIndicator());
        }

        // 2. 错误处理
        if (c.userFuture.hasError) {
          return Center(
            child: ElevatedButton(onPressed: () => c.userFuture.retry(), child: Text("加载失败，点击重试: ${c.userFuture.error}")),
          );
        }
        // 3. 数据展示
        final list = c.userList.value; // 或者使用 c.userFuture.data
        if (list.isEmpty) return Center(child: Text("暂无数据"));

        return ListView.builder(
          itemCount: list.length,
          itemBuilder: (ctx, idx) {
            // 关键点：使用 Rx 包裹每一项渲染逻辑
            return Rx(() {
              final user = c.userList.value[idx]; // 在 Rx 闭包内读取，建立依赖
              final selected = c.selectedIndex.value == idx;

              return ListTile(
                title: Text(user.name),
                subtitle: Text("年龄: ${user.age}"),
                tileColor: selected ? Colors.orange[100] : null,
                onTap: () => c.selectUser(idx),
                trailing: IconButton(icon: const Icon(Icons.add_circle), onPressed: () => c.updateUserAge(idx, user.age + 1)),
              );
            });
          },
        );
      }),
    );
  }
}


class FreatureHomePage extends StatelessWidget {
  const FreatureHomePage({super.key});

  @override
  Widget build(BuildContext context) {
    return RxParent<HomeController>(
      name: "homex", // 重要：多页面隔离 可省略
      dependency: HomeController(),
      child: const HomeView(),
    );
  }
}
