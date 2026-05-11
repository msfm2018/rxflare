import 'package:flutter/material.dart';
import 'package:rxflare/rxflare.dart';

// void main() {
//   runApp(const MyApp());
// }

class AppController {
  final counter = 0.obs;

  final loading = false.obs;

  final username = "Tom".obs;

  // final user = RxMap<String, dynamic>({"name": "Tom", "age": 18});
  final user ={"name": "Tom", "age": 18}.obsMapD;
  // final user = {"name": "Tom"}.obsMap<String, dynamic>();

 

  final stats = RxMap<String, dynamic>({"score": 100, "level": 1});

  /// RxList Demo
  final todos = ["Learn Flutter", "Learn RxFlare"].obsList();

  /// RxSet Demo（例如：收藏 / 选中集合）
  final tags = {"flutter", "dart"}.obsSet();
  void increment() {
    counter.value++;
  }

  void changeName() {
    user["name"] = "Jack ${counter.value}";
  }

  void addAge() {
    user["age"] = user["age"] + 1;
  }

  void addScore() {
    stats["score"] = stats["score"] + 10;
  }

  /// 修改第一个 todo
  void updateTodo() {
    if (todos.length > 0) {
      todos[0] = "Updated ${counter.value}";
    }
  }

  /// 添加 todo
  void addTodo() {
    todos.add("New Todo ${todos.length}");
  }

  /// 删除最后一个 todo
  void removeTodo() {
    if (todos.length > 0) {
      todos.removeAt(todos.length - 1);
    }
  }

  Future<void> fakeRequest() async {
    loading.value = true;

    await Future.delayed(const Duration(seconds: 2));

    loading.value = false;
  }

  /// 添加 tag
  void addTag() {
    tags.add("tag_${counter.value}");
  }

  /// 删除 tag
  void removeTag(String tag) {
    tags.remove(tag);
  }

  /// toggle（推荐）
  void toggleTag(String tag) {
    if (tags.contains(tag)) {
      tags.remove(tag);
    } else {
      tags.add(tag);
    }
  }
}

// class MyApp extends StatelessWidget {
//   const MyApp({super.key});

//   @override
//   Widget build(BuildContext context) {
//     return MaterialApp(debugShowCheckedModeBanner: false, home: HomePage());
//   }
// }

class Showcase extends StatelessWidget {
  Showcase({super.key});

  final c = AppController();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("RxFlare Fine-Grained Demo")),

      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),

        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            /// counter
            Rx(() {
              debugPrint("🔥 Counter Widget Rebuild");

              return Text("Counter: ${c.counter.value}", style: const TextStyle(fontSize: 32));
            }),

            const SizedBox(height: 20),

            /// username
            Rx(() {
              debugPrint("🔥 Username Widget Rebuild");

              return Text("Username: ${c.username.value}", style: const TextStyle(fontSize: 24));
            }),

            const SizedBox(height: 20),

            /// user.name
            Rx(() {
              debugPrint("🔥 User.name Widget Rebuild");

              return Text("Name: ${c.user["name"]}", style: const TextStyle(fontSize: 24));
            }),

            const SizedBox(height: 20),

            /// user.age
            Rx(() {
              debugPrint("🔥 User.age Widget Rebuild");

              return Text("Age: ${c.user["age"]}", style: const TextStyle(fontSize: 24));
            }),

            const SizedBox(height: 20),

            /// stats.score
            Rx(() {
              debugPrint("🔥 Score Widget Rebuild");

              return Text("Score: ${c.stats["score"]}", style: const TextStyle(fontSize: 24));
            }),

            const SizedBox(height: 30),

            const Divider(),

            const SizedBox(height: 20),

            const Text("RxList Demo", style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold)),

            const SizedBox(height: 20),

            /// list length
            Rx(() {
              debugPrint("🔥 Todo Length Rebuild");

              return Text("Todo Count: ${c.todos.length}", style: const TextStyle(fontSize: 22));
            }),

            const SizedBox(height: 20),

            /// first item
            Rx(() {
              debugPrint("🔥 Todo[0] Rebuild");

              if (c.todos.length == 0) {
                return const Text("Empty");
              }

              return Text("First Todo: ${c.todos[0]}", style: const TextStyle(fontSize: 22));
            }),

            const SizedBox(height: 20),

            /// full list
            Rx(() {
              debugPrint("🔥 Todo List Rebuild");

              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: List.generate(c.todos.length, (index) {
                  return Padding(
                    padding: const EdgeInsets.symmetric(vertical: 4),
                    child: Text("${index + 1}. ${c.todos[index]}", style: const TextStyle(fontSize: 18)),
                  );
                }),
              );
            }),

            const SizedBox(height: 30),

            /// loading
            Rx(() {
              debugPrint("🔥 Loading Widget Rebuild");

              return c.loading.value ? const CircularProgressIndicator() : const Text("Idle", style: TextStyle(fontSize: 22));
            }),
            const SizedBox(height: 30),

            const Text("RxSet Demo", style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold)),

            const SizedBox(height: 20),
            Rx(() {
              debugPrint("🔥 Tags Length Rebuild");

              return Text("Tags Count: ${c.tags.length}", style: const TextStyle(fontSize: 22));
            }),
            Rx(() {
              debugPrint("🔥 Tags List Rebuild");

              return Wrap(
                spacing: 8,
                children: c.tags.set.map((tag) {
                  final selected = c.tags.contains(tag);

                  return GestureDetector(
                    onTap: () => c.toggleTag(tag),
                    child: Chip(
                      label: Text(tag),
                      backgroundColor: selected ? Colors.blue : Colors.grey[300],
                      labelStyle: TextStyle(color: selected ? Colors.white : Colors.black),
                    ),
                  );
                }).toList(),
              );
            }),
          ],
        ),
      ),

      floatingActionButton: SingleChildScrollView(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            FloatingActionButton(heroTag: "1", onPressed: c.increment, child: const Icon(Icons.add)),

            const SizedBox(height: 12),

            FloatingActionButton(heroTag: "2", onPressed: c.changeName, child: const Icon(Icons.person)),

            const SizedBox(height: 12),

            FloatingActionButton(heroTag: "3", onPressed: c.addAge, child: const Icon(Icons.cake)),

            const SizedBox(height: 12),

            FloatingActionButton(heroTag: "4", onPressed: c.addScore, child: const Icon(Icons.sports_esports)),

            const SizedBox(height: 12),

            FloatingActionButton(heroTag: "5", onPressed: c.addTodo, child: const Icon(Icons.playlist_add)),

            const SizedBox(height: 12),

            FloatingActionButton(heroTag: "6", onPressed: c.updateTodo, child: const Icon(Icons.edit)),

            const SizedBox(height: 12),

            FloatingActionButton(heroTag: "7", onPressed: c.removeTodo, child: const Icon(Icons.delete)),

            const SizedBox(height: 12),

            FloatingActionButton(heroTag: "8", onPressed: c.fakeRequest, child: const Icon(Icons.cloud_download)),

            FloatingActionButton(heroTag: "9", onPressed: c.addTag, child: const Icon(Icons.tag)),
          ],
        ),
      ),
    );
  }
}
