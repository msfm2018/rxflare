// // // features/home/controller/home_controller.dart
// // import 'package:rxflare/rxflare.dart';

// // class HomeController {
// //   // 基础状态
// //   final count = 0.obs;
// //   final isLoading = false.obs;

// //   // Map 类型
// //   final user = {"name": "张三", "age": 5, "avatar": ""}.obs;

// //   // List 类型
// //   final products = <String>[].obs;

// //   // Computed 计算属性
// //   late final totalCount = computed(() => count.value * 10);
// //   // late final isAdult = computed(() => user.getItem('age') >= 18);
// //   late final isAdult = computed(() => user.value['age'] as num >= 18);
// //   // 异步请求
// //   late final userFuture = RxFuture(() => fetchUser());

// //   Future<Map<String, dynamic>> fetchUser() async {
// //     isLoading.value = true;
// //     await Future.delayed(const Duration(seconds: 1));
// //     isLoading.value = false;
// //     final result = {"name": "李四", "age": 28};

// //     // ✅ 关键：把数据更新到响应式变量中
// //     // user.value = result; // 整体替换
// //     // 或者字段更新（更推荐，颗粒度更细）
// //     user.update(result);
// //     return result;
// //   }

// //   void increment() => count.value++;

// //   void updateUserName(String name) {
// //     user.updateField("name", name);
// //   }

// //   void dispose() {
// //     userFuture.dispose();
// //   }
// // }

// // features/home/controller/home_controller.dart
// import 'package:rxflare/rxflare.dart';

// class HomeController {
//   final count = 0.obs;
//   final isLoading = false.obs;

//   // ==================== 主要数据 ====================
//   // 用户列表（推荐使用 .obs）
//   // final userList = <Map<String, dynamic>>[].obs;
//   final userList = [].obs;
// // final userList = <UserModel>[].obs;
//   // 可选：当前选中的用户索引
//   final selectedIndex = (-1).obs;

//   // Computed 示例
//   late final totalCount = computed(() => count.value * 10);

//   // 当前选中用户是否成年（示例）
//   late final selectedUserIsAdult = computed(() {
//     if (selectedIndex.value < 0 || selectedIndex.value >= userList.value.length) {
//       return false;
//     }
//     final age = userList.value[selectedIndex.value]['age'] as num? ?? 0;
//     return age >= 18;
//   });

//   // 异步请求
//   late final userFuture = RxFuture(() => fetchUserList());

//   /// 获取用户列表
//   Future<List<Map<String, dynamic>>> fetchUserList() async {
//     isLoading.value = true;

//     try {
//       await Future.delayed(const Duration(seconds: 1));

//       // 模拟返回列表数据
//       final result = [
//         {"id": 1, "name": "张三", "age": 17},
//         {"id": 2, "name": "李四", "age": 28},
//         {"id": 3, "name": "王五", "age": 35},
//       ];

//       // ✅ 关键：更新响应式列表
//       userList.value = result;

//       return result;
//     } finally {
//       isLoading.value = false;
//     }
//   }

//   void increment() => count.value++;

//   /// 更新列表中某一项（推荐使用）
//   void updateUser(int index, Map<String, dynamic> newData) {
//     userList.updateField(index, newData);
//   }

//   void selectUser(int index) {
//     selectedIndex.value = index;
//   }

//   void dispose() {
//     userFuture.dispose();
//   }
// }

// features/home/controller/home_controller.dart
import 'package:rxflare/rxflare.dart';
import '../models/user_model.dart';

class HomeController {
  final count = 0.obs;
  final isLoading = false.obs;

  // ==================== 用户列表（实体类版本）====================
  final userList = <UserModel>[].obs;

  // 当前选中的用户索引
  final selectedIndex = (-1).obs;

  // Computed 示例
  late final totalCount = computed(() => count.value * 10);

  // 当前选中用户是否成年
  late final selectedUserIsAdult = computed(() {
    final idx = selectedIndex.value;
    if (idx < 0 || idx >= userList.value.length) return false;
    return userList.value[idx].age >= 18;
  });

  // 异步请求
  late final userFuture = RxFuture(() => fetchUserList());

  /// 获取用户列表
  Future<List<UserModel>> fetchUserList() async {
    isLoading.value = true;

    try {
      await Future.delayed(const Duration(seconds: 1));

      // 模拟后端返回数据
      final List<Map<String, dynamic>> rawList = [
        {"id": 1, "name": "张三", "age": 17},
        {"id": 2, "name": "李四", "age": 28},
        {"id": 3, "name": "王五", "age": 35},
        {"id": 4, "name": "赵六", "age": 16},
      ];

      // 转换为实体类列表
      final users = rawList.map((e) => UserModel.fromMap(e)).toList();

      // ✅ 更新响应式列表
      userList.value = users;

      return users;
    } finally {
      isLoading.value = false;
    }
  }

  void increment() => count.value++;

  /// 更新指定索引的用户
  void updateUser(int index, UserModel newUser) {
    if (index >= 0 && index < userList.value.length) {
      userList.updateField(index, newUser);
    }
  }

  /// 选中用户
  void selectUser(int index) {
    selectedIndex.value = index;
  }

  void dispose() {
    userFuture.dispose();
    userList.dispose();
  }
}

// // 分页加载功能
// // features/home/controller/home_controller.dart
// import 'package:rxflare/rxflare.dart';
// import '../models/user_model.dart';

// class HomeController {
//   final count = 0.obs;
//   final isLoading = false.obs;

//   // 分页相关状态
//   final userList = <UserModel>[].obs;
//   final currentPage = 1.obs;
//   final pageSize = 20.obs;
//   final hasMore = true.obs;
//   final isLoadingMore = false.obs;

//   final selectedIndex = (-1).obs;

//   // Computed
//   late final totalCount = computed(() => count.value * 10);
//   late final selectedUserIsAdult = computed(() {
//     final idx = selectedIndex.value;
//     if (idx < 0 || idx >= userList.value.length) return false;
//     return userList.value[idx].age >= 18;
//   });

//   // 异步请求
//   late final userFuture = RxFuture(() => fetchUserList(page: 1));

//   /// 获取用户列表（支持分页）
//   Future<List<UserModel>> fetchUserList({required int page}) async {
//     isLoading.value = true;

//     try {
//       await Future.delayed(const Duration(seconds: 1)); // 模拟网络延迟

//       // 模拟后端分页数据
//       final start = (page - 1) * pageSize.value;
//       final end = start + pageSize.value;

//       final List<Map<String, dynamic>> rawData = List.generate(50, (index) {
//         return {
//           "id": index + 1,
//           "name": "用户 ${index + 1}",
//           "age": 15 + (index % 30),
//           "avatar": null,
//         };
//       });

//       final newUsers = rawData
//           .sublist(start, end.clamp(0, rawData.length))
//           .map((e) => UserModel.fromMap(e))
//           .toList();

//       if (page == 1) {
//         userList.value = newUsers;           // 第一页直接替换
//       } else {
//         userList.value = [...userList.value, ...newUsers]; // 加载更多
//       }

//       // 判断是否还有更多数据
//       hasMore.value = end < rawData.length;
//       currentPage.value = page;

//       return newUsers;
//     } catch (e) {
//       hasMore.value = false;
//       rethrow;
//     } finally {
//       isLoading.value = false;
//     }
//   }

//   /// 下拉刷新
//   Future<void> refresh() async {
//     currentPage.value = 1;
//     hasMore.value = true;
//     userFuture.refresh();   // 使用 RxFuture 的 refresh
//   }

//   /// 上拉加载更多
//   Future<void> loadMore() async {
//     if (isLoadingMore.value || !hasMore.value) return;

//     isLoadingMore.value = true;
//     final nextPage = currentPage.value + 1;

//     try {
//       await fetchUserList(page: nextPage);
//     } finally {
//       isLoadingMore.value = false;
//     }
//   }

//   void increment() => count.value++;

//   void selectUser(int index) {
//     selectedIndex.value = index;
//   }

//   void updateUser(int index, UserModel newUser) {
//     userList.updateField(index, newUser);
//   }

//   void dispose() {
//     userFuture.dispose();
//   }
// }




// // 局部更新
// // features/home/controller/home_controller.dart
// import 'package:rxflare/rxflare.dart';
// import '../models/user_model.dart';

// class HomeController {
//   final count = 0.obs;
//   final isLoading = false.obs;

//   final userList = <UserModel>[].obs;
//   final selectedIndex = (-1).obs;

//   late final userFuture = RxFuture(() => fetchUserList());

//   Future<List<UserModel>> fetchUserList() async {
//     isLoading.value = true;
//     await Future.delayed(const Duration(seconds: 1));

//     final rawList = [
//       {"id": 1, "name": "张三", "age": 17},
//       {"id": 2, "name": "李四", "age": 28},
//       {"id": 3, "name": "王五", "age": 35},
//     ];

//     userList.value = rawList.map((e) => UserModel.fromMap(e)).toList();
//     isLoading.value = false;
//     return userList.value;
//   }

//   /// ✅ 使用 copyWith 进行局部更新（推荐写法）
//   void updateUserAge(int index, int newAge) {
//     if (index < 0 || index >= userList.value.length) return;

//     final oldUser = userList.value[index];
//     final newUser = oldUser.copyWith(age: newAge);

//     // 关键：使用 updateField 实现精准更新
//     userList.updateField(index, newUser);
//   }

//   /// 批量字段更新示例
//   void updateUserInfo(int index, {String? name, int? age}) {
//     if (index < 0 || index >= userList.value.length) return;

//     final oldUser = userList.value[index];
//     final newUser = oldUser.copyWith(
//       name: name,
//       age: age,
//     );

//     userList.updateField(index, newUser);
//   }

//   void selectUser(int index) => selectedIndex.value = index;

//   void dispose() {
//     userFuture.dispose();
//   }
// }
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
//       appBar: AppBar(title: const Text("copyWith 局部更新示例")),
//       body: Rx(() {
//         if (c.userList.value.isEmpty) {
//           return const Center(child: CircularProgressIndicator());
//         }

//         return ListView.builder(
//           itemCount: c.userList.value.length,
//           itemBuilder: (context, index) {
//             final user = c.userList.value[index];
//             final isSelected = c.selectedIndex.value == index;

//             return Card(
//               margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
//               color: isSelected ? Colors.orange[50] : null,
//               child: ListTile(
//                 leading: CircleAvatar(child: Text(user.name[0])),
//                 title: Text(user.name),
//                 subtitle: Text("年龄: ${user.age}"),
//                 trailing: Row(
//                   mainAxisSize: MainAxisSize.min,
//                   children: [
//                     // 增加年龄按钮
//                     IconButton(
//                       icon: const Icon(Icons.add_circle, color: Colors.green),
//                       onPressed: () => c.updateUserAge(index, user.age + 1),
//                     ),
//                     // 减少年龄按钮
//                     IconButton(
//                       icon: const Icon(Icons.remove_circle, color: Colors.red),
//                       onPressed: () => c.updateUserAge(index, user.age - 1),
//                     ),
//                   ],
//                 ),
//                 onTap: () => c.selectUser(index),
//               ),
//             );
//           },
//         );
//       }),
//       floatingActionButton: Column(
//         mainAxisAlignment: MainAxisAlignment.end,
//         children: [
//           FloatingActionButton(
//             heroTag: "add",
//             onPressed: c.increment,
//             child: const Icon(Icons.add),
//           ),
//           const SizedBox(height: 12),
//           // 示例：修改选中用户的名字
//           FloatingActionButton(
//             heroTag: "edit",
//             onPressed: () {
//               if (c.selectedIndex.value >= 0) {
//                 c.updateUserInfo(
//                   c.selectedIndex.value,
//                   name: "修改后的名字",
//                   age: 30,
//                 );
//               }
//             },
//             child: const Icon(Icons.edit),
//           ),
//         ],
//       ),
//     );
//   }
// }