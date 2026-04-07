import 'package:flutter/material.dart';
import 'package:rxflare/rxflare.dart';

void main() {
  runApp(const MyApp());
}

class ContactCategory {
  final String id;
  final String name;
  int count;

  ContactCategory({required this.id, required this.name, this.count = 0});

  ContactCategory copyWith({int? count}) {
    return ContactCategory(id: id, name: name, count: count ?? this.count);
  }
}

class ChatController {
  final categories = RxList([ContactCategory(id: "new_friends", name: "新的朋友"), ContactCategory(id: "groupChats", name: "群聊")]);

  void addNewFriendRequest() {
    int idx = categories.value.indexWhere((e) => e.id == "new_friends");

    if (idx != -1) {
      var item = categories.value[idx];

      categories.updateField(idx, item.copyWith(count: item.count + 1));
    }
  }
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(home: const ContactPage());
  }
}

class ContactPage extends StatefulWidget {
  const ContactPage({super.key});

  @override
  State<ContactPage> createState() => _ContactPageState();
}

class _ContactPageState extends State<ContactPage> {
  late final ChatController logic;

  @override
  void initState() {
    super.initState();
    logic = ChatController();
  }

  @override
  Widget build(BuildContext context) {
    final categories = logic.categories.value;

    return RxParent<ChatController>(
      dependency: logic,
      child: Scaffold(
        appBar: AppBar(title: const Text("通讯录")),
        body: ListView.builder(
          itemCount: categories.length,
          itemBuilder: (context, index) {
            final item = categories[index];

            return ListTile(
              key: ValueKey(item.id),
              title: Text(item.name),

              // 👇 关键：只监听 index
              trailing: Rx(() {
                print("🔴 badge 更新 → item $index");

                final item = logic.categories.getItem(index) as ContactCategory;

                return CircleAvatar(radius: 12, child: Text("${item.count}", style: const TextStyle(fontSize: 12)));
              }),
            );
          },
        ),
        floatingActionButton: FloatingActionButton(onPressed: logic.addNewFriendRequest, child: const Icon(Icons.person_add)),
      ),
    );
  }
}

//map字段更新 
import 'package:flutter/material.dart';
import 'package:rxflare/rxflare.dart';

void main() {
  runApp(const MyApp());
}

class UserController {
  /// ✅ 必须是 RxState
  // final user = RxState<Map<String, Object>>(<String, Object>{"name": "张三", "age": 18, "unread": 0});
  // 这里的 Map 不要写泛型，或者写 <String, dynamic>
  // final user = RxState<Map>({
  //   "name": "张三",
  //   "age": 18,
  //   "unread": 0,
  // });
  // final user = RxState<Map<String, dynamic>>({
  //   "name": "张三",
  //   "age": 18,
  //   "unread": 0,
  // });
  final user = {"name": "张三", "age": 18, "unread": 0}.obs;
  void addUnread() {
    final current = user.getItem("unread") as int;

    user.updateField(
      "unread",
      current + 1,
      notifyGlobal: false, // ✅ 只更新 unread
    );
  }

  void changeName() {
    user.updateField(
      "name",
      "李四",
      notifyGlobal: false, // ✅ 只更新 name
    );
  }

  void addAge() {
    final current = user.getItem("age") as int;

    user.updateField("age", current + 1, notifyGlobal: false);
  }
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return const MaterialApp(home: UserPage());
  }
}

class UserPage extends StatefulWidget {
  const UserPage({super.key});

  @override
  State<UserPage> createState() => _UserPageState();
}

class _UserPageState extends State<UserPage> {
  final logic = UserController();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Map 字段监听（最终版）")),

      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          /// ✅ name（只监听 name）
          Rx(() {
            print("🟢 name 更新");

            final name = logic.user.getItem("name");

            return Text("姓名: $name");
          }),

          /// ✅ age（只监听 age）
          Rx(() {
            print("🟡 age 更新");

            final age = logic.user.getItem("age");

            return Text("年龄: $age");
          }),

          /// ✅ unread（只监听 unread）
          Rx(() {
            print("🔴 unread 更新");

            final unread = logic.user.getItem("unread");

            return Text("未读消息: $unread");
          }),

          const SizedBox(height: 20),

          ElevatedButton(onPressed: logic.addUnread, child: const Text("增加未读")),

          ElevatedButton(onPressed: logic.changeName, child: const Text("修改名字")),

          ElevatedButton(onPressed: logic.addAge, child: const Text("年龄+1")),
        ],
      ),
    );
  }
}

