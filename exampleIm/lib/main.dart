import 'package:flutter/material.dart';
import 'package:rxflare/rxflare.dart';


// ✅ 这里的类型会自动推导为 RxState<String>
final selectedId = "1".obs; 

final selectedNavIndex = 1.obs;

// 顺便把你的搜索词也改了，更整洁
final searchText = "".obs;


final chatList = <Map>[
   {"id": "1", "name": "文件传输助手", "msg": "等待接收文件...", "unread": 0, "color": Colors.green},
  {"id": "2", "name": "公众号", "msg": "[6条] 就业在北京...", "unread": 5, "color": Colors.blue},
  {"id": "3", "name": "拳之森林会员群", "msg": "教练：下午有课", "unread": 0, "color": Colors.teal},
  {"id": "4", "name": "王小静", "msg": "您好！", "unread": 0, "color": Colors.pinkAccent},
  ].obs;

// // ✅ 消息记录也统一使用 .obs
// final Map<String, RxState<List<Map<String, dynamic>>>> messagesMap = {
//   "1": [{"text": "[文件传输助手] 已连接", "isMe": false}].obs,
//   "2": [{"text": "欢迎关注公众号", "isMe": false}].obs,
//   "3": [{"text": "教练：下午有课", "isMe": false}].obs,
//   "4": [{"text": "王小静：您好！", "isMe": false}].obs,
// };
// 消息记录的定义，支持 Map 或对象

final Map<String, RxValue<List<Map<String, dynamic>>>> messagesMap = {

  "1": RxValue([
    {"text": "[文件传输助手] 已连接", "isMe": false},
  ]),

  "2": RxValue([
    {"text": "欢迎关注公众号", "isMe": false},
  ]),

  "3": RxValue([
    {"text": "教练：下午有课", "isMe": false},
  ]),

  "4": RxValue([
    {"text": "王小静：您好！", "isMe": false},
  ]),


};
void main() {
  // 开启 Rx 调试日志
   RxDebug.isEnabled = false;
   int listenerCount = 0;
  // --- 核心：使用 listen 实现自动持久化 ---
  for (var entry in messagesMap.entries) {
    listenerCount++;
    // 监听每个对话的消息流
    entry.value.listen((newMsgs) {
      final chatId = entry.key;
      final lastMsg = newMsgs.last;
      print("【系统日志----------------------->】对话 $chatId 产生新变动，正在同步到本地：$lastMsg");
      // 这里可以放置你的持久化代码，如：LocalDB.save(chatId, newMsgs);
    });
  }
  print("【初始化日志】共创建 $listenerCount 个消息监听器"); // 会打印：共创建 4 个（对应4个对话）
  runApp(MaterialApp(debugShowCheckedModeBanner: false, home: WeChatMainPage()));
}

// 替换原有的 StatelessWidget 定义
class WeChatMainPage extends StatefulWidget {
  const WeChatMainPage({super.key});

  @override
  State<WeChatMainPage> createState() => _WeChatMainPageState();
}

class _WeChatMainPageState extends State<WeChatMainPage> {
  final TextEditingController _inputController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  late VoidCallback _cancelListener;

  @override
  void initState() {
    super.initState();
    _cancelListener = chatList.listenField(3, (updatedItem) {
      print("【底层追踪】王小静字段变动：${updatedItem['msg']}");
      if (updatedItem["unread"] > 0) {
        print("【强提醒】${updatedItem['name']} 发来了 ${updatedItem['unread']} 条紧急消息！");
      }
    });
  }

@override
  void dispose() {
    // 2. 手动调用闭包，释放监听器（核心操作）
    _cancelListener();
    RxDebug.log("✅ 王小静的监听器已手动释放");
    // 同时释放控制器（避免额外内存泄漏）
    _inputController.dispose();
    _scrollController.dispose();
    
    super.dispose();
  }
// 1. 模拟触发器
void _simulateLiSiIncoming() {
  // 模拟李四在 1 秒后发来第一条消息
  Future.delayed(const Duration(milliseconds: 500), () {
    _addNewChatMember(
      id: "5",
      name: "李四",
      firstMsg: "嘿！我是李四，有人在吗？",
      color: Colors.orange,
    );
  });
}

// 2. 核心初始化方法
void _addNewChatMember({
  required String id,
  required String name,
  required String firstMsg,
  required Color color,
}) {
  // 防止重复创建
  if (messagesMap.containsKey(id)) {
    print("【提示】$name 已在列表中");
    return;
  }

  // ✅ 关键：显式声明 List<Map<String, dynamic>> 解决 Object 类型错误
  final List<Map<String, dynamic>> initialData = [
    {"text": firstMsg, "isMe": false}
  ];

  final newRxValue = RxValue<List<Map<String, dynamic>>>(initialData);

  // ✅ 绑定持久化监听（新成员专用）
  newRxValue.listen((newMsgs) {
    final last = newMsgs.last;
    print("【李四频道日志】收到新变动：${last['text']}");
  });

  // 放入全局 Map
  messagesMap[id] = newRxValue;

  // 更新左侧列表 (chatList.value 需要重新赋值触发 Rx 响应)
  final Map<String, dynamic> newListEntry = {
    "id": id,
    "name": name,
    "msg": firstMsg,
    "unread": 1,
    "color": color
  };
  
  // 使用解构赋值确保 chatList 整体更新
  chatList.value = [...chatList.value, newListEntry];

  print("✅ 成功为 $name (ID: $id) 建立独立监听通道");
}
// 2. 模拟文件上传（rxflare 局部更新演示）
  void _uploadFileSimulation(String id, String fileName) async {
    // 获取当前消息列表长度作为新消息的索引
    int msgIdx = messagesMap[id]!.value.length;
    
    // 初始化一条带进度的消息
    _addMessage(id, fileName, isMe: true, progress: 0.1);

    for (double i = 0.2; i <= 1.05; i += 0.2) {
      await Future.delayed(const Duration(milliseconds: 400));
      
      // 关键：克隆列表并更新特定索引的对象
      var currentMsgs = List<Map<String, dynamic>>.from(messagesMap[id]!.value);
      currentMsgs[msgIdx] = {
        ...currentMsgs[msgIdx],
        "progress": i > 1.0 ? 1.0 : i,
      };
      
      // 触发 rxflare 响应
      messagesMap[id]!.value = currentMsgs; 
    }
  }


// 1. 发送消息
  void _sendMessage() {
    final text = _inputController.text.trim();
    if (text.isEmpty) return;

    final currentId = selectedId.value;

    if (currentId == "1") {
      // 文件传输助手：走进度条逻辑，不触发回复
      _uploadFileSimulation(currentId, text);
    } else {
      // 其他：先发送我的消息
      _addMessage(currentId, text, isMe: true);

      // --- 关键逻辑控制 ---
      // 只有王小静 (ID: 4) 才触发自动回复
      // 群 (ID: 3) 和 公众号 (ID: 2) 保持静默
      if (currentId == "4") {
        _triggerAutoReply(currentId, text);
      }
    }

    _inputController.clear();
    _scrollToBottom();
  }
  // 抽离出一个添加消息的通用方法，方便自己发和机器人回

// 3. 统一的消息添加方法
void _addMessage(String id, String text, {bool isMe = true, double? progress}) {
    final msgs = messagesMap[id]!;
    
    // 构造消息对象
    final newMsg = {
      "text": text,
      "isMe": isMe,       // 根据传入参数决定左右
      "progress": progress,
    };

    // 更新消息列表
    msgs.value = [...msgs.value, newMsg];

    // 更新左侧列表的预览文案
    int idx = chatList.value.indexWhere((e) => e["id"] == id);
    if (idx != -1) {
      chatList.updateField(idx, {
        ...chatList.value[idx],
        "msg": text,
        "unread": (id != selectedId.value) ? (chatList.value[idx]["unread"] + 1) : 0,
      });
    }
  }

  // 3. 自动回复逻辑
 // 3. 自动回复逻辑：修正发送者身份
void _triggerAutoReply(String id, String userText) async {
    // 模拟思考延迟
    await Future.delayed(const Duration(milliseconds: 800));

    String reply = "收到您的消息：'$userText'，稍后回复您。";
    if (userText.contains("在吗")) reply = "小主，我一直都在呢~";

    // 重点：isMe 设为 false，表示对方发送
    _addMessage(id, reply, isMe: false);
    _scrollToBottom();
  }

  void _scrollToBottom() {
    Future.delayed(const Duration(milliseconds: 50), () {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(_scrollController.position.maxScrollExtent, duration: const Duration(milliseconds: 200), curve: Curves.easeOut);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Row(
        children: [
          _buildSideBar(),
          // 聊天列表栏
          Container(
            width: 280,
            color: const Color(0xFFE6E5E5),
            child: Column(
              children: [
                const SizedBox(height: 40),
                Expanded(child: _buildDynamicChatList()),
              ],
            ),
          ),
          // 聊天详情窗口
          Expanded(child: _buildChatWindow()),
        ],
      ),
    );
  }

  // --- 新增搜索词状态 ---
  final RxValue<String> searchText = RxValue("");
  final TextEditingController _searchController = TextEditingController();

  // 修改后的左侧列表区
  Widget _buildDynamicChatList() {
    return Column(
      children: [
        // 1. 搜索框
        Padding(
          padding: const EdgeInsets.all(10),
          child: Container(
            height: 30,
            decoration: BoxDecoration(color: const Color(0xFFDBD9D8), borderRadius: BorderRadius.circular(4)),
            child: TextField(
              controller: _searchController,
              onChanged: (val) => searchText.value = val, // 实时同步搜索词
              decoration: const InputDecoration(
                hintText: "搜索",
                hintStyle: TextStyle(fontSize: 12, color: Colors.grey),
                prefixIcon: Icon(Icons.search, size: 16, color: Colors.grey),
                border: InputBorder.none,
                isDense: true,
                contentPadding: EdgeInsets.symmetric(vertical: 6),
              ),
            ),
          ),
        ),
        // 2. 过滤后的列表
        Expanded(
          child: Rx(() {
            // 根据搜索词过滤
            final filteredList = chatList.value.where((item) {
              return item["name"].toString().contains(searchText.value);
            }).toList();

            if (filteredList.isEmpty) {
              return const Center(
                child: Text("无匹配结果", style: TextStyle(color: Colors.grey)),
              );
            }

            return ListView.builder(
              itemCount: filteredList.length,
              itemBuilder: (context, index) {
                final item = filteredList[index];
                final id = item["id"];
                // 嵌套 Rx 监听选中状态
                return Rx(() {
                  final isSelected = selectedId.value == id;
                  return GestureDetector(
                    onTap: () {
                      selectedId.value = id;
                      if (item["unread"] > 0) {
                        // 注意：updateField 最好操作原始 chatList 的 index
                        int originalIdx = chatList.value.indexWhere((e) => e["id"] == id);
                        chatList.updateField(originalIdx, {...item, "unread": 0});
                      }
                      _scrollToBottom();
                    },
                    child: Container(
                      padding: const EdgeInsets.all(12),
                      color: isSelected ? const Color(0xFFCBC9C8) : Colors.transparent,
                      child: Row(
                        children: [
                          _buildAvatar(item),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(item["name"], style: const TextStyle(fontSize: 14)),
                                Text(
                                  item["msg"],
                                  style: const TextStyle(color: Colors.grey, fontSize: 12),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                });
              },
            );
          }),
        ),
      ],
    );
  }

  // --- 右侧聊天窗口 ---
  Widget _buildChatWindow() {
    return Column(
      children: [
        // 标题栏
        Container(
          height: 55,
          padding: const EdgeInsets.symmetric(horizontal: 20),
          alignment: Alignment.centerLeft,
          decoration: const BoxDecoration(
            color: Color(0xFFF3F3F3),
            border: Border(bottom: BorderSide(color: Color(0xFFDEDEDE))),
          ),
          child: Rx(() {
            final currentItem = chatList.value.firstWhere((e) => e["id"] == selectedId.value);
            return Text(currentItem["name"], style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold));
          }),
        ),
        // 消息列表区
        Expanded(
          child: Container(
            color: const Color(0xFFF3F3F3),
            child: Rx(() {
              final msgs = messagesMap[selectedId.value]?.value ?? [];
              return ListView.builder(controller: _scrollController, padding: const EdgeInsets.all(20), itemCount: msgs.length, itemBuilder: (context, i) => _buildMsgBubble(msgs[i]));
            }),
          ),
        ),
        // 输入区
        _buildInputArea(),
      ],
    );
  }

 Widget _buildMsgBubble(Map<String, dynamic> msgData) {
    final String text = msgData["text"];
    final bool isMe = msgData["isMe"] ?? true;
    final double? progress = msgData["progress"];

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
      child: Row(
        mainAxisAlignment: isMe ? MainAxisAlignment.end : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (!isMe) ...[_buildStaticAvatar(selectedId.value), const SizedBox(width: 8)],
          Flexible(
            child: Stack(
              clipBehavior: Clip.none,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                  decoration: BoxDecoration(
                    color: isMe ? const Color(0xFF95EC69) : Colors.white,
                    borderRadius: BorderRadius.circular(6).copyWith(
                      bottomLeft: isMe ? null : Radius.zero,
                      bottomRight: isMe ? Radius.zero : null,
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(text, style: const TextStyle(fontSize: 15, height: 1.4)),
                      // 进度条渲染
                      if (progress != null) ...[
                        const SizedBox(height: 8),
                        if (progress < 1.0) ...[
                          LinearProgressIndicator(
                            value: progress,
                            backgroundColor: Colors.black12,
                            valueColor: const AlwaysStoppedAnimation(Colors.blue),
                            minHeight: 2,
                          ),
                          const SizedBox(height: 4),
                          Text("${(progress * 100).toInt()}%", style: const TextStyle(fontSize: 10, color: Colors.blue)),
                        ] else ...[
                          const Text("已传输 ✓", style: TextStyle(fontSize: 10, color: Colors.grey)),
                        ]
                      ],
                    ],
                  ),
                ),
                // 气泡小尖角
                isMe 
                  ? Positioned(top: 10, right: -4, child: _buildTriangle(const Color(0xFF95EC69))) 
                  : Positioned(top: 10, left: -4, child: _buildTriangle(Colors.white)),
              ],
            ),
          ),
          if (isMe) ...[const SizedBox(width: 8), _buildMyAvatar()],
        ],
      ),
    );
  }

  Widget _buildMyAvatar() {
    return const CircleAvatar(
      radius: 18,
      backgroundColor: Colors.blueGrey,
      child: Icon(Icons.person, size: 20, color: Colors.white),
    );
  }

  // 抽象出小尾巴组件
  Widget _buildTriangle(Color color) {
    return Transform.rotate(
      angle: 0.8, // 旋转 45 度左右模拟角
      child: Container(
        width: 10,
        height: 10,
        decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(1)),
      ),
    );
  }

  // 辅助方法：获取当前聊天的头像
  Widget _buildStaticAvatar(String id) {
    final item = chatList.value.firstWhere((e) => e["id"] == id, orElse: () => chatList.value.first);

    return Container(
      width: 36,
      height: 36,
      decoration: BoxDecoration(color: item["color"], borderRadius: BorderRadius.circular(4)),
      child: id == "1" ? const Icon(Icons.folder, color: Colors.white, size: 20) : (id == "2" ? const Icon(Icons.campaign, color: Colors.white, size: 20) : null),
    );
  }

  Widget _buildInputArea() {
    return Container(
      height: 160,
      color: Colors.white,
      padding: const EdgeInsets.all(12),
      child: Column(
        children: [
          Expanded(
            child: TextField(
              controller: _inputController,
              maxLines: null,
              decoration: const InputDecoration(border: InputBorder.none, hintText: "输入消息..."),
            ),
          ),
          Align(
            alignment: Alignment.bottomRight,
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFE9E9E9), elevation: 0),
              onPressed: _sendMessage,
              child: const Text("发送(S)", style: TextStyle(color: Colors.green)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAvatar(Map item) {
    return Stack(
      clipBehavior: Clip.none,
      children: [
        Container(
          width: 45,
          height: 45,
          decoration: BoxDecoration(color: item["color"], borderRadius: BorderRadius.circular(4)),
        ),
        if (item["unread"] > 0)
          Positioned(
            right: -5,
            top: -5,
            child: CircleAvatar(
              radius: 9,
              backgroundColor: Colors.red,
              child: Text("${item["unread"]}", style: const TextStyle(color: Colors.white, fontSize: 10)),
            ),
          ),
      ],
    );
  }

  Widget _buildSideBar() {
    return Container(
      width: 60,
      color: const Color(0xFF2E2E2E),
      child: Column(
        children: [
          const SizedBox(height: 40),
          const CircleAvatar(radius: 18, backgroundColor: Colors.blueGrey),
          const SizedBox(height: 20),
          Rx(
            () => IconButton(
              icon: Icon(Icons.chat, color: selectedNavIndex.value == 1 ? Colors.green : Colors.grey),
              onPressed: () => selectedNavIndex.value = 1,
            ),
          ),
          // --- 新增：点击这个模拟李四发消息 ---
        const SizedBox(height: 20),
        IconButton(
          icon: const Icon(Icons.person_add, color: Colors.orangeAccent),
          tooltip: "模拟李四发消息",
          onPressed: _simulateLiSiIncoming, // 调用模拟方法
        ),
          const Spacer(),
          const Icon(Icons.menu, color: Colors.grey),
          const SizedBox(height: 20),
        ],
      ),
    );
  }
}



