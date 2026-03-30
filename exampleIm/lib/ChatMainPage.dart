import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:rxflare/rxflare.dart';

import 'loginAuth.dart';
import 'chat_service.dart';
import 'emojiPickerPanel.dart';
import 'entry.dart';
import 'imagePreviewPage.dart';
import 'persistenceService.dart';
import 'publishMomentPage.dart';
import 'utils.dart';

final searchText = "".obs;

// 在类成员变量区定义
final contactSearchText = "".obs;
final TextEditingController _contactSearchController = TextEditingController();

// 替换原有的 StatelessWidget 定义
class WeChatMainPage extends StatefulWidget {
  const WeChatMainPage({super.key});

  @override
  State<WeChatMainPage> createState() => _WeChatMainPageState();
}

class _WeChatMainPageState extends State<WeChatMainPage> {
  final TextEditingController _inputController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final auth = RxObjMgr.find<AuthService>(); // 获取全局用户
  final isLoggingOut = false.obs;
  final chat = RxObjMgr.find<ChatService>();

  @override
  void initState() {
    super.initState();
  }

  @override
  void dispose() {
    _inputController.dispose();
    _scrollController.dispose();

    super.dispose();
  }

  void _showAddMemberSheet(BuildContext context, ChatItem currentChat) {
    final chat = RxObjMgr.find<ChatService>();
    // 使用 rxflare 局部变量记录选中的人
    final selectedIds = <String>[].obs;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(12))),
      builder: (context) => Container(
        height: MediaQuery.of(context).size.height * 0.8, // 占 80% 高度
        child: Column(
          children: [
            // 头部：取消和确定
            _buildSheetHeader(context, selectedIds, currentChat),

            // 搜索框（可选，模仿微信）
            Padding(
              padding: const EdgeInsets.all(10),
              child: TextField(
                decoration: InputDecoration(
                  hintText: "搜索",
                  prefixIcon: const Icon(Icons.search),
                  fillColor: Colors.grey[100],
                  filled: true,
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide.none),
                ),
              ),
            ),

            // 联系人列表
            Expanded(
              child: Rx(() {
                // 过滤掉当前已经在聊天里的人（你自己和对方）
                final availableContacts = chat.allContacts.value.where((c) => c.type == "contacts" && c.id != currentChat.id).toList();

                return ListView.builder(
                  itemCount: availableContacts.length,
                  itemBuilder: (ctx, index) {
                    final contact = availableContacts[index];
                    return Rx(() {
                      bool isChecked = selectedIds.contains(contact.id);
                      return ListTile(
                        leading: _buildAvatar(contact),
                        title: Text(contact.name),
                        trailing: Icon(isChecked ? Icons.check_circle : Icons.radio_button_unchecked, color: isChecked ? const Color(0xFF07C160) : Colors.grey),
                        onTap: () {
                          if (isChecked) {
                            selectedIds.remove(contact.id);
                          } else {
                            selectedIds.add(contact.id);
                          }
                        },
                      );
                    });
                  },
                );
              }),
            ),
          ],
        ),
      ),
    );
  }

  Widget buildContactManagerBtn() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
      child: InkWell(
        // 加上点击效果
        onTap: _simulateAddNewContact, // ✅ 点击这里测试动态添加
        child: Container(
          height: 40,
          decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(4)),
          child: const Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.person_add_alt_1_outlined, size: 18, color: Colors.black87),
              SizedBox(width: 8),
              Text("测试：添加好友", style: TextStyle(fontSize: 13)), // 修改文字方便识别
            ],
          ),
        ),
      ),
    );
  }

  // 弹窗头部
  Widget _buildSheetHeader(BuildContext context, RxList<String> selectedIds, ChatItem currentChat) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 10),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text("取消")),
          const Text("选择联系人", style: TextStyle(fontWeight: FontWeight.bold)),
          Rx(
            () => ElevatedButton(
              // 注意：这里的 isEmpty 是你 extension 定义的
              onPressed: selectedIds.isEmpty
                  ? null
                  : () {
                      final chatService = RxObjMgr.find<ChatService>();

                      // ✅ 关键：传入 selectedIds.value (List<String>)
                      chatService.createGroupFromChat(currentChat.id, selectedIds.value);

                      Navigator.pop(context);
                    },
              child: Text("确定(${selectedIds.length})"),
            ),
          ),
        ],
      ),
    );
  }

  // 1. 模拟触发器
  void _simulateLiSiIncoming() {
    // 模拟李四在 1 秒后发来第一条消息
    Future.delayed(const Duration(milliseconds: 500), () {
      _addNewChatMember(id: "5", name: "李四", firstMsg: "嘿！我是李四，有人在吗？", color: Colors.orange);
    });
  }

  void _addNewChatMember({required String id, required String name, required String firstMsg, required Color color}) {
    if (chat.messagesMap.containsKey(id)) return;

    // ✅ 修复：传入必填的 senderId
    final List<Message> initialData = [
      Message(
        text: firstMsg,
        senderId: id, // 发送者就是这个新成员
        isMe: false,
        time: DateTime.now().millisecondsSinceEpoch,
      ),
    ];

    final newRxValue = RxValue<List<Message>>(initialData);

    newRxValue.listen((newMsgs) {
      final last = newMsgs.last;
      print("【$name频道】收到新消息：${last.text}");
    });

    chat.messagesMap[id] = newRxValue;
    RxObjMgr.find<PersistenceService>().watch(id, newRxValue);

    final newItem = ChatItem(id: id, type: "contact", name: name, msg: firstMsg, unread: 1, color: color, lastTime: DateTime.now().millisecondsSinceEpoch, isPinned: false);

    chat.chatList.value = [...chat.chatList.value, newItem];
    print("✅ 成功为 $name (ID: $id) 建立独立监听通道");
  }

  // 2. 模拟文件上传（rxflare 局部更新演示）
  void _uploadFileSimulation(String id, String fileName) async {
    // 1. 获取当前 RxValue 引用
    final rxMsgs = chat.messagesMap[id]!;
    int msgIdx = rxMsgs.value.length;

    // 2. 发送初始消息 (确保 _addMessage 内部也已经改成了 new Message)
    _addMessage(id, fileName, isMe: true, progress: 0.1);

    for (double i = 0.2; i <= 1.05; i += 0.2) {
      await Future.delayed(const Duration(milliseconds: 400));

      // ✅ 修复点 1：使用 List<Message> 而不是 List<Map>
      var currentMsgs = List<Message>.from(rxMsgs.value);

      // ✅ 修复点 2：使用 copyWith 更新对象，而不是 Map 的解构
      if (msgIdx < currentMsgs.length) {
        currentMsgs[msgIdx] = currentMsgs[msgIdx].copyWith(progress: i > 1.0 ? 1.0 : i);
      }

      // ✅ 修复点 3：重新赋值触发 rxflare 更新
      rxMsgs.value = currentMsgs;
    }
  }

  // 1. 发送消息
  void _sendMessage() {
    final text = _inputController.text.trim();
    if (text.isEmpty) return;

    final currentId = chat.selectedId.value;
    //对u1 特殊处理
    if (currentId == "s1") {
      // 文件传输助手：走进度条逻辑，不触发回复
      _uploadFileSimulation(currentId, text);
    } else {
      // 其他：先发送我的消息
      _addMessage(currentId, text, isMe: true);

      // 只有王小静 (ID: u1) 才触发自动回复
      // 群 (ID: 3) 和 公众号 (ID: 2) 保持静默
      if (currentId == "u1") {
        _triggerAutoReply(currentId, text);
      }
    }

    _inputController.clear();
    _scrollToBottom();
  }

  void _addMessage(String id, String text, {bool isMe = true, double? progress}) {
    final msgs = chat.messagesMap[id];
    if (msgs == null) return;

    final now = DateTime.now().millisecondsSinceEpoch;

    // ✅ 修复：添加 senderId。如果是本人，通常用 "me"，否则用对方的 id
    final newMsg = Message(
      text: text,
      isMe: isMe,
      senderId: isMe ? "me" : id, // 确保传参
      time: now,
      progress: progress,
    );

    msgs.value = [...msgs.value, newMsg];

    // 3️⃣ 更新左侧 chatList 中的预览信息和时间戳
    int idx = chat.chatList.value.indexWhere((e) => e.id == id);
    if (idx != -1) {
      final current = chat.chatList.value[idx];

      // 获取当前最新时间
      final newTime = DateTime.now().millisecondsSinceEpoch;
      print("正在更新 ${current.name} 的时间戳为: $newTime");

      // 计算未读数：如果不是当前选中的对话，未读数+1
      int newUnread = (id != chat.selectedId.value && !isMe) ? current.unread + 1 : 0;

      // 更新字段
      chat.chatList.updateField(
        idx,
        current.copyWith(
          msg: text,
          lastTime: newTime, // 确保时间是最新的
          unread: newUnread,
        ),
      );

      // 4️⃣ 执行排序（确保王小静排到第一位）
      chat.sortChatList();
    } else {
      print("警告：在 chatList 中未找到 ID 为 $id 的用户");
    }
  }

  void _triggerAutoReply(String id, String userText) async {
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

  Widget _buildExitButton() {
    return Rx(() {
      if (isLoggingOut.value) {
        return const SizedBox(
          width: 48,
          height: 48,
          child: Padding(
            padding: EdgeInsets.all(12),
            child: CircularProgressIndicator(strokeWidth: 2, color: Colors.redAccent),
          ),
        );
      }

      return IconButton(
        icon: const Icon(Icons.power_settings_new, color: Colors.redAccent),
        onPressed: _handleLogout, // 调用上面的优化逻辑
        tooltip: "退出登录",
      );
    });
  }

  // 修改后的 _handleLogout
  void _handleLogout() async {
    // 1. 防抖：如果正在退出，直接返回
    if (isLoggingOut.value) return;

    // 2. 开启转圈
    isLoggingOut.value = true;

    try {
      // 3. 执行 Service 中的退出逻辑（包含 800ms 延迟）
      await auth.logout();
    } catch (e) {
      isLoggingOut.value = false;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Row(
        children: [
          _buildSideBar(),

          // 2. 占据剩余所有空间的页面内容区
          Expanded(
            child: Rx(() {
              // 这里的 Rx 会监听 selectedNavIndex.value 的变化
              return IndexedStack(
                // 对应 children 列表的索引
                index: chat.selectedNavIndex.value - 1,
                children: [
                  _buildChatModule(), // index: 0 (selectedNavIndex = 1)
                  _buildContactModule(), // index: 1 (selectedNavIndex = 2)
                  _buildCollectionModule(), // index: 2 (selectedNavIndex = 3)
                  _buildMomentsModule(),
                  // 如果还有 index 4，在这里继续加，否则点击 4 会报错
                  const Center(child: Text("发现模块 - 待开发")),
                ],
              );
            }),
          ),
        ],
      ),
    );
  }

  // --- 模块 D: 朋友圈模块 ---
  Widget _buildMomentsModule() {
    return Scaffold(
      // 给朋友圈模块加个独立的 Scaffold 方便放浮动按钮或 AppBar
      floatingActionButton: FloatingActionButton(
        backgroundColor: const Color(0xFF07C160),
        child: const Icon(Icons.camera_alt, color: Colors.white),
        onPressed: () {
          Navigator.push(context, MaterialPageRoute(builder: (c) => const PublishMomentPage()));
        },
      ),
      body: CustomScrollView(
        slivers: [
          // 1. 顶部封面与个人头像
          SliverToBoxAdapter(
            child: SizedBox(
              height: 320,
              child: Stack(
                clipBehavior: Clip.none,
                children: [
                  // 封面图
                  Container(
                    height: 280,
                    width: double.infinity,
                    decoration: const BoxDecoration(
                      image: DecorationImage(image: NetworkImage("https://picsum.photos/800/500"), fit: BoxFit.cover),
                    ),
                  ),
                  // 头像
                  Positioned(
                    right: 20,
                    bottom: 15,
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        const Text(
                          "我",
                          style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold, shadows: [Shadow(blurRadius: 5)]),
                        ),
                        const SizedBox(width: 15),
                        Container(
                          width: 70,
                          height: 70,
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(8),
                            image: const DecorationImage(image: NetworkImage("https://picsum.photos/100"), fit: BoxFit.cover),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
          // 2. 动态列表
          Rx(() {
            final list = chat.momentsList.value;
            return SliverList(delegate: SliverChildBuilderDelegate((context, index) => _buildMomentItem(list[index]), childCount: list.length));
          }),
          const SliverToBoxAdapter(child: SizedBox(height: 50)),
        ],
      ),
    );
  }

  Widget _buildMomentImagesHero(List images, String momentId) {
    if (images.isEmpty) return const SizedBox.shrink();

    return Padding(
      padding: const EdgeInsets.only(top: 8),
      child: Wrap(
        spacing: 5,
        runSpacing: 5,
        children: List.generate(images.length, (index) {
          String url = images[index].toString();
          String tag = "hero_${momentId}_$index";

          // 核心修改：让图片在鼠标悬停时显示“小手”
          return MouseRegion(
            cursor: SystemMouseCursors.click,
            child: GestureDetector(
              onTap: () {
                // 点击弹出大图预览 (Hero 动画)
                Navigator.push(
                  context,
                  PageRouteBuilder(
                    opaque: false,
                    barrierColor: Colors.black,
                    pageBuilder: (_, __, ___) => ImagePreviewPage(url: url, heroTag: tag),
                  ),
                );
              },
              child: Hero(
                tag: tag,
                child: Container(
                  width: images.length == 1 ? 200 : 80,
                  height: images.length == 1 ? 150 : 80,
                  decoration: BoxDecoration(
                    color: Colors.grey[200],
                    borderRadius: BorderRadius.circular(4),
                    image: DecorationImage(image: NetworkImage(url), fit: BoxFit.cover),
                  ),
                ),
              ),
            ),
          );
        }),
      ),
    );
  }

  // 单条动态内容
  Widget _buildMomentItem(Map item) {
    return Padding(
      padding: const EdgeInsets.all(15),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 左侧头像
          buildNetworkAvatar(item["avatarColor"] == Colors.pink ? "https://picsum.photos/101" : "https://picsum.photos/102", radius: 22),
          const SizedBox(width: 12),
          // 右侧内容
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item["userName"],
                  style: const TextStyle(color: Color(0xFF576B95), fontWeight: FontWeight.bold, fontSize: 16),
                ),
                const SizedBox(height: 5),
                Text(item["content"], style: const TextStyle(fontSize: 15, height: 1.4)),
                _buildMomentImagesHero(item["images"] as List, item["id"].toString()), // 九宫格图片
                const SizedBox(height: 12),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(formatTime(item["publishTime"]), style: const TextStyle(color: Colors.grey, fontSize: 12)),
                    _buildMomentActionBtn(item), // 点赞按钮
                  ],
                ),
                _buildLikeAndCommentsArea(item), // 点赞和评论展示区
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMomentActionBtn(Map item) {
    return PopupMenuButton<String>(
      // 偏移量，让弹窗出现在按钮左侧
      offset: const Offset(-10, 0),
      // 自定义按钮外观
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(color: const Color(0xFFF7F7F7), borderRadius: BorderRadius.circular(4)),
        child: const Icon(Icons.more_horiz, size: 20, color: Color(0xFF576B95)),
      ),
      // 弹窗背景和样式
      color: const Color(0xFF4C4C4C),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),

      // 核心修正：显式声明返回类型
      itemBuilder: (BuildContext context) {
        bool isLiked = (item["likes"] as List).contains("我");

        return <PopupMenuEntry<String>>[
          PopupMenuItem<String>(
            height: 35,
            onTap: () {
              // 注意：PopupMenuButton 的 onTap 在菜单关闭后触发
              // 这里建议直接调用 service
              chat.toggleLike(item["id"], "我");
            },
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(isLiked ? Icons.favorite : Icons.favorite_border, color: Colors.white, size: 16),
                const SizedBox(width: 8),
                Text(isLiked ? "取消" : "点赞", style: const TextStyle(color: Colors.white, fontSize: 14)),
              ],
            ),
          ),
          // 这里的分割线也是 PopupMenuEntry 的子类，没问题
          const PopupMenuDivider(height: 1),
          PopupMenuItem<String>(
            height: 35,
            onTap: () {
              // 稍后异步弹出评论框
              Future.delayed(Duration.zero, () => _showCommentDialog(item["id"]));
            },
            child: const Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.chat_bubble_outline, color: Colors.white, size: 16),
                const SizedBox(width: 8),
                Text("评论", style: TextStyle(color: Colors.white, fontSize: 14)),
              ],
            ),
          ),
        ];
      },
    );
  }

  // 简单的评论对话框
  void _showCommentDialog(String momentId) {
    final controller = TextEditingController();
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("发表评论", style: TextStyle(fontSize: 16)),
        content: TextField(
          controller: controller,
          autofocus: true,
          decoration: const InputDecoration(hintText: "评论内容"),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text("取消")),
          ElevatedButton(
            onPressed: () {
              if (controller.text.isNotEmpty) {
                chat.addComment(momentId, "我", controller.text);
                Navigator.pop(context);
              }
            },
            child: const Text("发送"),
          ),
        ],
      ),
    );
  }

  Widget _buildLikeAndCommentsArea(Map item) {
    bool hasLikes = item["likes"].isNotEmpty;
    bool hasComments = item["comments"].isNotEmpty;
    if (!hasLikes && !hasComments) return const SizedBox.shrink();

    return Container(
      margin: const EdgeInsets.only(top: 10),
      width: double.infinity,
      decoration: BoxDecoration(color: const Color(0xFFF3F3F5), borderRadius: BorderRadius.circular(4)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (hasLikes)
            Padding(
              padding: const EdgeInsets.all(8),
              child: Row(
                children: [
                  const Icon(Icons.favorite_border, size: 14, color: Color(0xFF576B95)),
                  const SizedBox(width: 5),
                  Expanded(
                    child: Text(
                      item["likes"].join(", "),
                      style: const TextStyle(color: Color(0xFF576B95), fontWeight: FontWeight.bold, fontSize: 13),
                    ),
                  ),
                ],
              ),
            ),
          if (hasLikes && hasComments) const Divider(height: 1, indent: 8, endIndent: 8),
          if (hasComments)
            Padding(
              padding: const EdgeInsets.all(8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: item["comments"]
                    .map<Widget>(
                      (c) => Padding(
                        padding: const EdgeInsets.only(bottom: 4),
                        child: RichText(
                          text: TextSpan(
                            style: const TextStyle(fontSize: 14, color: Colors.black87),
                            children: [
                              TextSpan(
                                text: "${c['from']}: ",
                                style: const TextStyle(color: Color(0xFF576B95), fontWeight: FontWeight.bold),
                              ),
                              TextSpan(text: c['content']),
                            ],
                          ),
                        ),
                      ),
                    )
                    .toList(),
              ),
            ),
        ],
      ),
    );
  }

  // --- 新增搜索词状态 ---
  final TextEditingController _searchController = TextEditingController();
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
              onChanged: (val) => searchText.value = val,
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

        // 2. 列表
        Expanded(
          child: Rx(() {
            // 生成 filteredList，每次 Rx 更新都会重新计算
            final filteredList = chat.chatList.value.where((item) => item.name.contains(searchText.value)).toList();

            if (filteredList.isEmpty) {
              return const Center(
                child: Text("无匹配结果", style: TextStyle(color: Colors.grey)),
              );
            }

            return ListView.builder(
              itemCount: filteredList.length,
              itemBuilder: (context, index) {
                final id = filteredList[index].id;

                return Rx(() {
                  final currentItem = chat.chatList.value.firstWhere((e) => e.id == id);
                  final isSelected = chat.selectedId.value == id;

                  return GestureDetector(
                    onTap: () {
                      chat.selectedId.value = id;

                      if (currentItem.unread > 0) {
                        int originalIdx = chat.chatList.value.indexWhere((e) => e.id == id);

                        chat.chatList.updateField(originalIdx, currentItem.copyWith(unread: 0));
                      }

                      _scrollToBottom();
                    },
                    onSecondaryTapDown: (details) {
                      _showChatContextMenu(details.globalPosition, currentItem);
                    },
                    child: Container(
                      padding: const EdgeInsets.all(12),
                      color: isSelected ? const Color(0xFFCBC9C8) : Colors.transparent,
                      child: Row(
                        children: [
                          _buildAvatar(
                            Contact(
                              id: currentItem.id,
                              name: currentItem.name,
                              avatar: currentItem.name.isNotEmpty ? currentItem.name[0] : "?",
                              color: currentItem.color,
                              type: currentItem.type,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Expanded(
                                      child: Row(
                                        children: [
                                          Expanded(
                                            child: Text(currentItem.name, style: const TextStyle(fontSize: 14), overflow: TextOverflow.ellipsis),
                                          ),
                                          if (currentItem.unread > 0)
                                            Container(
                                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                              decoration: BoxDecoration(color: Colors.red, borderRadius: BorderRadius.circular(10)),
                                              child: Text(currentItem.unread > 99 ? "99+" : "${currentItem.unread}", style: const TextStyle(color: Colors.white, fontSize: 10)),
                                            ),
                                        ],
                                      ),
                                    ),
                                    Text(formatTime(currentItem.lastTime), style: const TextStyle(fontSize: 10, color: Colors.grey)),
                                  ],
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  currentItem.msg,
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

  // 这里的 item 类型是 ChatItem
  void _showChatContextMenu(Offset position, ChatItem item) {
    // 直接使用 State 类的 context
    final overlay = Overlay.of(context);
    final chat = RxObjMgr.find<ChatService>();

    late OverlayEntry entry;

    entry = OverlayEntry(
      builder: (ctx) => Stack(
        // 这里的 ctx 是内部 builder 的，不影响外部
        children: [
          // 遮罩层：点击其余地方关闭菜单
          Positioned.fill(
            child: GestureDetector(
              onTap: () => entry.remove(),
              onSecondaryTapDown: (_) => entry.remove(), // 右键其他地方也关闭
              child: Container(color: Colors.transparent),
            ),
          ),
          // 菜单主体
          Positioned(
            left: position.dx,
            top: position.dy,
            child: Material(
              elevation: 8,
              borderRadius: BorderRadius.circular(4),
              child: Container(
                width: 140,
                padding: const EdgeInsets.symmetric(vertical: 5),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(4),
                  border: Border.all(color: Colors.grey.shade300, width: 0.5),
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    _menuItem(item.isPinned ? "取消置顶" : "置顶", () {
                      chat.togglePin(item.id);
                      entry.remove();
                    }),
                    _menuItem("标记为已读", () {
                      // 这里可以调用你清除未读数的逻辑
                      entry.remove();
                    }),
                    const Divider(height: 1),
                    _menuItem("移除会话", () {
                      chat.deleteUiContact(item.id);
                      entry.remove();
                    }),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );

    overlay.insert(entry);
  }

  Widget _buildChatWindow() {
    return Rx(() {
      final selectedId = chat.selectedId.value;

      // 1. 安全检查：如果没有选中 ID，直接返回占位符，不执行后面的逻辑
      if (selectedId.isEmpty) return _buildEmptyState();

      // 2. 尝试从列表中寻找当前选中的 item (使用 firstWhereOrNull 的逻辑)
      // 这样如果找不到，currentItem 会是 null，而不会崩溃
      final chatItems = chat.chatList.value;
      final currentItem = chatItems.cast<ChatItem?>().firstWhere((e) => e?.id == selectedId, orElse: () => null);

      // 3. 如果会话被删除了（找不到对应 item），显示占位符
      if (currentItem == null) return _buildEmptyState();

      // 4. 只有确定有数据，才渲染真实的聊天窗口
      return Column(
        children: [
          Container(
            height: 55,
            padding: const EdgeInsets.symmetric(horizontal: 15),
            decoration: const BoxDecoration(
              color: Color(0xFFF3F3F3),
              border: Border(bottom: BorderSide(color: Color(0xFFDEDEDE))),
            ),
            child: Row(
              children: [
                // 聊天标题
                Text(currentItem.name, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),

                const Spacer(),

                // 📞（可选）
                IconButton(icon: const Icon(Icons.call, size: 20), onPressed: () {}),

                // 📹（可选）
                IconButton(icon: const Icon(Icons.videocam, size: 20), onPressed: () {}),

                // ❗核心：群聊入口（加号）
                IconButton(
                  icon: const Icon(Icons.more_horiz, size: 20),
                  onPressed: () {
                    _showAddMemberSheet(context, currentItem);
                  },
                ),
              ],
            ),
          ),
          // 消息列表区
          Expanded(
            child: Container(
              color: const Color(0xFFF3F3F3),
              child: Rx(() {
                final List<Message> msgs = chat.messagesMap[selectedId]?.value ?? [];
                return ListView.builder(controller: _scrollController, padding: const EdgeInsets.all(20), itemCount: msgs.length, itemBuilder: (context, i) => _buildMsgBubble(msgs[i]));
              }),
            ),
          ),
          // 输入区
          _buildInputArea(),
        ],
      );
    });
  }

  // 补充一个简单的占位图方法
  Widget _buildEmptyState() {
    return Container(
      color: const Color(0xFFF3F3F3),
      child: const Center(child: Icon(Icons.chat_bubble_outline, size: 80, color: Color(0xFFE0E0E0))),
    );
  }

  Widget buildGroupAvatar(List<Contact> members) {
    final display = members.take(9).toList(); // 最多9个

    return Container(
      width: 40,
      height: 40,
      decoration: BoxDecoration(color: Colors.grey[300], borderRadius: BorderRadius.circular(6)),
      child: GridView.builder(
        padding: const EdgeInsets.all(2),
        physics: const NeverScrollableScrollPhysics(),
        itemCount: display.length,
        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: display.length <= 4 ? 2 : 3, crossAxisSpacing: 2, mainAxisSpacing: 2),
        itemBuilder: (_, i) {
          final c = display[i];
          return Container(
            decoration: BoxDecoration(color: c.color, borderRadius: BorderRadius.circular(3)),
            alignment: Alignment.center,
            child: Text(c.avatar, style: const TextStyle(fontSize: 10, color: Colors.white)),
          );
        },
      ),
    );
  }

  Widget _buildMsgBubble(Message msg) {
    // 以前是 msgData["text"]，现在直接访问对象的属性
    final String text = msg.text;
    final bool isMe = msg.isMe;
    final double? progress = msg.progress;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
      child: Row(
        mainAxisAlignment: isMe ? MainAxisAlignment.end : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (!isMe) ...[_buildStaticAvatar(chat.selectedId.value), const SizedBox(width: 8)],
          Flexible(
            child: Stack(
              clipBehavior: Clip.none,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                  decoration: BoxDecoration(
                    color: isMe ? const Color(0xFF95EC69) : Colors.white,
                    borderRadius: BorderRadius.circular(6).copyWith(bottomLeft: isMe ? null : Radius.zero, bottomRight: isMe ? Radius.zero : null),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(text, style: const TextStyle(fontSize: 15, height: 1.4)),
                      // 进度条逻辑同样改为对象访问
                      if (progress != null) ...[
                        const SizedBox(height: 8),
                        if (progress < 1.0) ...[
                          LinearProgressIndicator(value: progress, backgroundColor: Colors.black12, valueColor: const AlwaysStoppedAnimation(Colors.blue), minHeight: 2),
                          const SizedBox(height: 4),
                          Text("${(progress * 100).toInt()}%", style: const TextStyle(fontSize: 10, color: Colors.blue)),
                        ] else ...[
                          const Text("已传输 ✓", style: TextStyle(fontSize: 10, color: Colors.grey)),
                        ],
                      ],
                    ],
                  ),
                ),
                // 气泡小尖角
                isMe ? Positioned(top: 12, right: -4, child: _buildTriangle(const Color(0xFF95EC69))) : Positioned(top: 12, left: -4, child: _buildTriangle(Colors.white)),
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
    final item = chat.chatList.value.firstWhere((e) => e.id == id, orElse: () => chat.chatList.value.first);

    return Container(
      width: 36,
      height: 36,
      decoration: BoxDecoration(color: item.color, borderRadius: BorderRadius.circular(4)),
      child: id == "1" ? const Icon(Icons.folder, color: Colors.white, size: 20) : (id == "2" ? const Icon(Icons.campaign, color: Colors.white, size: 20) : null),
    );
  }

  Widget _buildInputArea() {
    return Container(
      height: 160,
      color: Colors.white,
      padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 8),
      child: Column(
        children: [
          // 1. 工具栏 (表情、文件、剪刀等)
          Row(
            children: [
              CompositedTransformTarget(
                link: _emojiLayerLink,
                child: _buildToolIcon(Icons.sentiment_satisfied_alt_outlined, "表情", onTap: _toggleEmojiPicker),
              ),

              _buildToolIcon(Icons.grid_view_outlined, "扩展"),
              _buildToolIcon(Icons.folder_open_outlined, "文件"),
              _buildToolIcon(Icons.content_cut_outlined, "截图"),
              _buildToolIcon(Icons.mic_none_outlined, "语音消息"),
            ],
          ),

          Expanded(
            child: KeyboardListener(
              focusNode: FocusNode(),
              onKeyEvent: (KeyEvent event) {
                if (event is KeyDownEvent && event.logicalKey == LogicalKeyboardKey.enter && !HardwareKeyboard.instance.isControlPressed) {
                  _sendMessage();
                }
              },
              child: TextField(
                controller: _inputController,
                maxLines: null,
                style: const TextStyle(fontSize: 14),
                textInputAction: TextInputAction.newline,
                decoration: const InputDecoration(border: InputBorder.none, hintText: "输入消息...", isDense: true, contentPadding: EdgeInsets.symmetric(vertical: 5)),
                onSubmitted: (_) => _sendMessage(),
              ),
            ),
          ),

          // 3. 发送按钮
          Align(
            alignment: Alignment.bottomRight,
            child: Container(
              margin: const EdgeInsets.only(bottom: 5),
              width: 80,
              height: 30,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFF5F5F5), // 浅灰色背景
                  foregroundColor: const Color(0xFF07C160), // 绿色文字
                  elevation: 0,
                  padding: EdgeInsets.zero,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
                ),
                onPressed: _sendMessage,
                child: const Text("发送(S)", style: TextStyle(fontSize: 12)),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // 记得稍微改下 _buildToolIcon 接收 onTap 参数
  Widget _buildToolIcon(IconData icon, String tip, {VoidCallback? onTap}) {
    return Tooltip(
      message: tip,
      child: MouseRegion(
        cursor: SystemMouseCursors.click,
        child: GestureDetector(
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.only(right: 15, top: 5, bottom: 10),
            child: Icon(icon, color: Colors.black54, size: 20),
          ),
        ),
      ),
    );
  }

  Widget _buildAvatar(Contact item) {
    return Container(
      width: 35,
      height: 35,
      decoration: BoxDecoration(
        color: item.color, // 使用 Contact 对象的 Color 对象
        borderRadius: BorderRadius.circular(4),
      ),
      child: Center(
        child: Text(
          // item.name[0], // 取名字首字母
          item.name.isNotEmpty ? item.name[0] : "?",
          style: const TextStyle(color: Colors.white, fontSize: 18),
        ),
      ),
    );
  }

  Widget _buildSideBar() {
    final String userAvatarUrl = "https://pics2.baidu.com/feed/4610b912c8fcc3ce9cd9bd6ad8583687d43f207e.jpeg";
    return Container(
      width: 79,
      color: const Color(0xFF2E2E2E),
      child: Column(
        children: [
          const SizedBox(height: 40),

          // 头像
          // buildNetworkAvatar(userAvatarUrl),
          GestureDetector(
            onTap: () {
              _showMyProfile(context);
            },
            child: buildNetworkAvatar(userAvatarUrl),
          ),

          const SizedBox(height: 25),

          const SizedBox(height: 25),

          // 2. 中间：核心功能区 (1: 聊天, 2: 通讯录, 3: 收藏, 4: 朋友圈)
          _buildNavIcon(Icons.chat_bubble_outline, Icons.chat_bubble, 1),
          _buildNavIcon(Icons.person_outline, Icons.person, 2),
          _buildNavIcon(Icons.collections_bookmark_outlined, Icons.collections_bookmark, 3),
          _buildNavIcon(Icons.explore_outlined, Icons.explore, 4),

          // --- 新增：点击这个模拟李四发消息 ---
          const SizedBox(height: 20),
          IconButton(
            icon: const Icon(Icons.person_add, color: Colors.orangeAccent),
            tooltip: "模拟李四发消息",
            onPressed: _simulateLiSiIncoming, // 调用模拟方法
          ),
          const Spacer(),

          // 4. 底部：小工具区
          _buildExitButton(),
          const Spacer(),
          // 菜单图标
          _buildBottomMinorIcon(Icons.menu),
          const SizedBox(height: 20),
        ],
      ),
    );
  }

  void _showMyProfile(BuildContext context) {
    final auth = RxObjMgr.find<AuthService>();

    showDialog(
      context: context,
      barrierDismissible: true,
      builder: (_) {
        return Rx(() {
          final user = auth.currentUser.value;

          if (user == null) {
            return const SizedBox();
          }

          return Dialog(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            child: Container(
              width: 300,
              padding: const EdgeInsets.all(20),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  buildNetworkAvatar(user.avatar),
                  const SizedBox(height: 12),

                  Text(
                    user.name, // 🔥 动态
                    style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),

                  const SizedBox(height: 6),

                  // 🆔 ID
                  Text(
                    "微信号：${user.id}", // 🔥 动态
                    style: const TextStyle(color: Colors.grey),
                  ),

                  const SizedBox(height: 16),

                  const Divider(),

                  // ✏️ 编辑按钮
                  ListTile(
                    leading: const Icon(Icons.edit),
                    title: const Text("编辑资料"),
                    onTap: () {
                      Navigator.pop(context);
                      // 👉 跳转编辑页（后面可以做）
                    },
                  ),

                  // ⚙️ 设置
                  ListTile(leading: const Icon(Icons.settings), title: const Text("设置"), onTap: () {}),
                ],
              ),
            ),
          );
        });
      },
    );
  }

  // --- 模块 A: 聊天模块 (原来的代码搬到这里) ---
  Widget _buildChatModule() {
    return Row(
      children: [
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
        Expanded(child: _buildChatWindow()),
      ],
    );
  }

  Widget _buildContactModule() {
    return Row(
      children: [
        // 1. 左侧联系人分类列表
        Container(
          width: 280,
          decoration: const BoxDecoration(
            color: Color(0xFFE6E5E5),
            border: Border(right: BorderSide(color: Color(0xFFDEDEDE), width: 0.5)),
          ),
          child: Column(
            children: [
              const SizedBox(height: 40),
              // 搜索框
              _buildContactSearchBar(),
              // “通讯录管理”按钮
              buildContactManagerBtn(),
              const Divider(height: 1, color: Color(0xFFD1D1D1)), // 分割线
              // 分类列表
              Expanded(child: _buildContactCategoryList()),
            ],
          ),
        ),

        Expanded(
          child: Container(
            color: const Color(0xFFF3F3F3),
            child: _buildContactDetailArea(), // ✅ 放在这里
          ),
        ),
      ],
    );
  }

  Widget _buildContactSearchBar() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      child: Container(
        height: 30,
        decoration: BoxDecoration(color: const Color(0xFFDBD9D8), borderRadius: BorderRadius.circular(4)),
        child: TextField(
          controller: _contactSearchController,
          // ✅ 核心：当文字改变时，更新响应式变量
          // onChanged: (val) => contactSearchText.value = val,
          onChanged: (val) {
            contactSearchText.value = val;

            // ✅ 核心修改：如果搜索框空了，把右侧选中的 ID 也清空
            if (val.trim().isEmpty) {
              chat.selectedContactId.value = "";
            }
          },
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
    );
  }

  Widget _buildContactCategoryList() {
    final chat = RxObjMgr.find<ChatService>();

    return Rx(() {
      final query = contactSearchText.value.trim();
      final selectedId = chat.selectedContactId.value; // 获取当前选中的 ID
      final isExpanded = chat.isContactsExpanded.value; // 读取展开状态
      // --- 情况 A: 正在搜索 ---
      if (query.isNotEmpty) {
        final filteredContacts = chat.allContacts.value.where((contact) {
          return contact.name.toLowerCase().contains(query.toLowerCase());
        }).toList();

        if (filteredContacts.isEmpty) {
          return const Center(
            child: Text("未找到联系人", style: TextStyle(color: Colors.grey, fontSize: 13)),
          );
        }

        return ListView.builder(
          itemCount: filteredContacts.length,
          itemBuilder: (context, index) {
            // 复用你已有的联系人 Item 组件
            return _buildContactItem(filteredContacts[index]);
          },
        );
      }

      // --- 情况 B: 默认显示（原有的分类列表逻辑） ---
      final list = chat.contactCategories.value;
      return ListView.builder(
        itemCount: list.length,
        itemBuilder: (context, index) {
          final item = list[index];
          final bool isContacts = item.id == "contacts";

          if (isContacts) {
            return Column(
              // 移除多余的 Rx，外层已经有了
              children: [
                _buildCategoryItem(
                  item,
                  onTap: () {
                    // ✅ 这里取反改变状态
                    chat.isContactsExpanded.value = !chat.isContactsExpanded.value;
                    chat.selectedContactId.value = "contacts";
                  },
                  isExpanded: isExpanded, // ✅ 使用 Rx 内部读取到的值
                  isSelected: selectedId == "contacts",
                ),
                // ✅ 状态改变后，这里会根据 true/false 自动显示或隐藏
                if (isExpanded) _buildEmbeddedContactList(),
              ],
            );
          }

          return _buildCategoryItem(
            item,
            isSelected: selectedId == item.id, // <--- 传入选中状态
            onTap: () => chat.selectedContactId.value = item.id,
          );
        },
      );
    });
  }

  // 分类列表项
  // 修改参数，增加 isSelected
  Widget _buildCategoryItem(ContactCategory item, {VoidCallback? onTap, bool isExpanded = false, bool isSelected = false}) {
    return InkWell(
      onTap: onTap,
      child: Container(
        // ✅ 核心修复：根据是否选中切换背景色，否则点完没反应
        color: isSelected ? const Color(0xFFC5C5C5) : Colors.transparent,
        padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 12),
        child: Row(
          children: [
            // 只有联系人分类显示旋转箭头
            if (item.id == "contacts") Icon(isExpanded ? Icons.keyboard_arrow_down : Icons.keyboard_arrow_right, size: 18, color: Colors.grey) else const SizedBox(width: 18), // 占位对齐

            const SizedBox(width: 5),
            Container(
              padding: const EdgeInsets.all(4),
              decoration: BoxDecoration(color: item.color, borderRadius: BorderRadius.circular(4)),
              child: Icon(item.icon, size: 20, color: Colors.white),
            ),
            const SizedBox(width: 12),
            Text(item.name, style: const TextStyle(fontSize: 14)),
            const Spacer(),
            if (item.count > 0) Text("${item.count}", style: const TextStyle(color: Colors.grey, fontSize: 12)),
          ],
        ),
      ),
    );
  }

  Widget _buildEmbeddedContactList() {
    final chat = RxObjMgr.find<ChatService>();

    return Rx(() {
      // ✅ 修复：直接过滤并转为 List<Contact>，不要转成 Map
      final contacts = chat.allContacts.value.where((e) => e.type == "contacts").toList(); // 👈 删掉 .cast<Map<String, dynamic>>()

      final groupedList = chat.getGroupedContacts(contacts);

      return Container(
        color: const Color(0xFFF2F2F2),
        child: ListView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: groupedList.length,
          itemBuilder: (context, index) {
            final item = groupedList[index];

            // 1. 渲染标题行
            if (item["type"] == "header") {
              return buildSubHeader(item["icon"], item["label"]);
            }

            // 2. 渲染联系人行
            // ✅ 修复：由于我们在 getGroupedContacts 里把对象存到了 item["data"]
            final Contact contactObj = item["data"];
            return _buildContactItem(contactObj);
          },
        ),
      );
    });
  }

  // 模拟通讯录动态更新
  void _simulateNewContactRequest() {
    final chat = RxObjMgr.find<ChatService>();

    // 找到“新的朋友”的索引
    int idx = chat.contactCategories.value.indexWhere((e) => e.id == "new_friends");

    if (idx != -1) {
      // 使用 rxflare 的 updateField 局部更新数据
      var currentItem = chat.contactCategories.value[idx];
      chat.contactCategories.updateField(idx, currentItem.copyWith(count: currentItem.count + 1));

      print("🔔 收到新的好友申请！");
    }
  }

  // --- 模块 C: 收藏模块 ---
  Widget _buildCollectionModule() {
    return const Center(child: Text("我的收藏 - 这里的状态也会被 IndexedStack 保留"));
  }

  // 辅助：底部那些不需要切换状态的小图标
  Widget _buildBottomMinorIcon(IconData icon) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Icon(icon, color: const Color(0xFF919191), size: 22),
    );
  }

  // 构建侧边栏功能图标（增加：Tooltip提示 + 鼠标手型）
  Widget _buildNavIcon(IconData normalIcon, IconData selectedIcon, int index) {
    // 1. 定义提示文字
    String label = "";
    switch (index) {
      case 1:
        label = "聊天";
        break;
      case 2:
        label = "通讯录";
        break;
      case 3:
        label = "收藏";
        break;
      case 4:
        label = "朋友圈";
        break;
      default:
        label = "功能";
    }

    return Rx(() {
      final bool isSelected = chat.selectedNavIndex.value == index;

      // 2. 增加 Tooltip 气泡提示
      return Tooltip(
        message: label,
        preferBelow: false,
        child: MouseRegion(
          // 3. 核心：设置鼠标悬停时显示“小手” (SystemMouseCursors.click)
          cursor: SystemMouseCursors.click,
          child: GestureDetector(
            onTap: () {
              chat.selectedNavIndex.value = index;
            },
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 12),
              child: Icon(isSelected ? selectedIcon : normalIcon, color: isSelected ? const Color(0xFF07C160) : const Color(0xFF919191), size: 28),
            ),
          ),
        ),
      );
    });
  }

  Widget _buildContactDetailArea() {
    final chat = RxObjMgr.find<ChatService>();

    return Rx(() {
      final selectedId = chat.selectedContactId.value;

      // 默认欢迎页 (未选择分类时)
      if (selectedId.isEmpty || selectedId == "contacts" || selectedId == "group_chats" || selectedId == "new_friends") {
        return Center(child: Opacity(opacity: 0.1, child: Image.network("https://res.wx.qq.com/a/wx_fed/assets/res/OTE0YTAw.png", width: 200)));
      }

      // // ✅ 当点击左侧“联系人”项时
      // if (selectedId == "contacts") {
      //   return _buildFriendGroupList();
      // }

      // ✅ 3. 如果点击的是具体的联系人（从 allContacts 中找到该用户）
      final Contact? contact = chat.allContacts.value.cast<Contact?>().firstWhere((e) => e?.id == selectedId, orElse: () => null);

      // ✅ 2. 判断逻辑
      if (contact != null) {
        // 如果是群组类型，显示群组详情界面
        if (contact.type == "group_chats") {
          // 修复：使用 contact.id 获取该群的成员 ID 列表
          final ids = chat.groupMembersMap[contact.id]?.value ?? [];

          final members = chat.allContacts.value.where((c) => ids.contains(c.id)).toList();

          // 返回你定义的群头像组件
          return Center(child: buildGroupAvatar(members));
        }
        return _buildContactInfoCard(contact);
      }

      return Center(child: Text("正在查看：$selectedId 的内容"));
    });
  }

  // ✅ 参数类型从 Map 改为 Contact
  Widget _buildContactInfoCard(Contact contact) {
    final chat = RxObjMgr.find<ChatService>();

    return Container(
      color: const Color(0xFFF3F3F3),
      child: Column(
        children: [
          const SizedBox(height: 100),

          // 1. 头像和名字
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 100),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          // ✅ 改为对象访问：contact.name
                          Text(contact.name, style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
                          const SizedBox(width: 8),
                          const Icon(Icons.person, color: Colors.blue, size: 20),
                        ],
                      ),
                      const SizedBox(height: 10),
                      const Text("这个家伙很懒，什么都没有留下", style: TextStyle(color: Colors.grey, fontSize: 14)),
                    ],
                  ),
                ),
                // 大头像
                Container(
                  width: 65,
                  height: 65,
                  decoration: BoxDecoration(
                    color: contact.color, // ✅ 改为对象访问：contact.color
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Center(
                    // ✅ 既然是 Contact 类，你可以直接取名字的首字母
                    child: Text(contact.name[0], style: const TextStyle(color: Colors.white, fontSize: 24)),
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 40),
          const Divider(indent: 100, endIndent: 100, color: Color(0xFFDEDEDE)),

          // 2. 详细信息行
          _buildInfoRow("备    注", "点击添加备注"),
          _buildInfoRow("微信号", "wxid_${contact.id}"), // ✅ contact.id
          _buildInfoRow("地    区", "中国 深圳"),

          const SizedBox(height: 40),
          const Divider(indent: 100, endIndent: 100, color: Color(0xFFDEDEDE)),

          // 3. 底部发消息按钮
          const SizedBox(height: 40),
          ElevatedButton(
            onPressed: () {
              // ✅ 核心优化：直接传递对象给 openChatWith，不要零散传参
              chat.openChatWith(contact);

              // selectedNavIndex.value = 1; // 切到聊天页
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF07C160),
              padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 15),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
              elevation: 0,
            ),
            child: const Text("发消息", style: TextStyle(color: Colors.white, fontSize: 16)),
          ),
        ],
      ),
    );
  }

  // 辅助行组件
  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 100, vertical: 12),
      child: Row(
        children: [
          SizedBox(
            width: 80,
            child: Text(label, style: const TextStyle(color: Colors.grey, fontSize: 14)),
          ),
          Text(value, style: const TextStyle(fontSize: 14, color: Colors.black87)),
        ],
      ),
    );
  }

  Widget _buildContactItem(Contact item) {
    final chat = RxObjMgr.find<ChatService>();

    return Rx(() {
      bool isSelected = chat.selectedContactId.value == item.id;
      bool isStar = item.isStar; // 直接访问类的布尔字段

      return GestureDetector(
        // ✅ 这里会调用你之前改好的 _showContextMenu(Offset, Contact)
        onSecondaryTapDown: (details) => _showContextMenu(details.globalPosition, item),
        onLongPressStart: (details) => _showContextMenu(details.globalPosition, item),
        onTap: () => chat.selectedContactId.value = item.id,

        child: Container(
          // 背景颜色切换：选中态样式
          color: isSelected ? const Color(0xFFC5C5C5) : Colors.transparent,
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
          child: Row(
            children: [
              // ✅ 记得同步修改 _buildAvatar 的接收类型
              _buildAvatar(item),
              const SizedBox(width: 12),
              Expanded(child: Text(item.name, style: const TextStyle(fontSize: 14))),
              // 如果是星标朋友，显示一个小星星
              if (isStar) const Icon(Icons.star, size: 14, color: Colors.orange),
            ],
          ),
        ),
      );
    });
  }

  // ✅ 参数 item 类型改为 Contact
  void _showContextMenu(Offset position, Contact item) {
    final overlay = Overlay.of(context);
    final chat = RxObjMgr.find<ChatService>();

    late OverlayEntry entry;

    // ✅ 改为点语法访问对象属性
    bool isStar = item.isStar;

    entry = OverlayEntry(
      builder: (context) => Stack(
        children: [
          Positioned.fill(
            child: GestureDetector(
              onTap: () => entry.remove(),
              child: Container(color: Colors.transparent),
            ),
          ),
          Positioned(
            left: position.dx,
            top: position.dy,
            child: Material(
              elevation: 6,
              borderRadius: BorderRadius.circular(6),
              child: Container(
                width: 140,
                padding: const EdgeInsets.symmetric(vertical: 6),
                decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(6)),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    _menuItem(isStar ? "取消标星" : "标为星标朋友", () {
                      chat.toggleStar(item.id); // ✅ item.id
                      entry.remove();
                    }),
                    // ✅ 假设你在 Contact 类里定义了 isPinned
                    _menuItem(item.isPinned ? "取消置顶" : "置顶聊天", () {
                      chat.togglePin(item.id);
                      entry.remove();
                    }),
                    _menuItem("发送消息", () {
                      // ✅ 直接传对象，比传一堆参数优雅多了
                      chat.openChatWith(item);
                      // selectedNavIndex.value = 1;
                      entry.remove();
                    }),
                    _menuItem("删除联系人", () {
                      chat.deleteContact(item.id);
                      entry.remove();
                    }),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );

    overlay.insert(entry);
  }

  // 模拟：从网络同步或手动添加一个新联系人
  void _simulateAddNewContact() {
    final chat = RxObjMgr.find<ChatService>();

    // ✅ 1. 直接构造 Contact 对象，而不是 Map
    final newFriend = Contact(
      id: "u${DateTime.now().millisecondsSinceEpoch}",
      name: "新朋友 ${chat.allContacts.value.length + 1}",
      avatar: "新",
      color: Colors.teal,
      type: "contacts",
      // 如果你的 Contact 类还有其他字段，记得也加上
      isStar: false,
    );

    // ✅ 2. 局部更新。因为 RxFlare 监听的是 value，这样写会触发 UI 刷新
    chat.allContacts.value = [...chat.allContacts.value, newFriend];

    // 3. (可选) 给“新的朋友”增加红点计数
    _simulateNewContactRequest();

    print("✅ 已成功添加新联系人：${newFriend.name}");
  }

  void showRightMenu(BuildContext context, Offset position) {
    final overlay = Overlay.of(context);
    late OverlayEntry entry;

    entry = OverlayEntry(
      builder: (context) => Stack(
        children: [
          // 点击空白关闭
          Positioned.fill(
            child: GestureDetector(
              onTap: () => entry.remove(),
              child: Container(color: Colors.transparent),
            ),
          ),

          Positioned(
            left: position.dx,
            top: position.dy,
            child: Material(
              elevation: 4,
              borderRadius: BorderRadius.circular(6),
              child: Container(
                width: 120,
                padding: const EdgeInsets.symmetric(vertical: 6),
                decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(6)),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    _menuItem("复制", () {
                      entry.remove();
                    }),
                    _menuItem("删除", () {
                      entry.remove();
                    }),
                    _menuItem("转发", () {
                      entry.remove();
                    }),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );

    overlay.insert(entry);
  }

  Widget _menuItem(String text, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 16),
        child: Row(children: [Text(text)]),
      ),
    );
  }

  // 在 State 类中定义控制弹窗的 LayerLink
  final LayerLink _emojiLayerLink = LayerLink();
  OverlayEntry? _emojiOverlay;

  void _toggleEmojiPicker() {
    if (_emojiOverlay != null) {
      _emojiOverlay?.remove();
      _emojiOverlay = null;
    } else {
      _emojiOverlay = _createEmojiOverlay();
      Overlay.of(context).insert(_emojiOverlay!);
    }
  }

  OverlayEntry _createEmojiOverlay() {
    return OverlayEntry(
      builder: (context) => Stack(
        children: [
          // 点击背景关闭弹窗
          GestureDetector(
            onTap: _toggleEmojiPicker,
            child: Container(color: Colors.transparent),
          ),
          // 定位到按钮上方
          Positioned(
            width: 300,
            child: CompositedTransformFollower(
              link: _emojiLayerLink,
              showWhenUnlinked: false,
              offset: const Offset(0, -210), // 向上偏移（高度200 + 间距10）
              child: EmojiPickerPanel(
                onEmojiSelected: (emoji) {
                  final text = _inputController.text;
                  final selection = _inputController.selection;

                  String newText;
                  int newCursorPosition;

                  // 关键修复：判断光标是否有效 (>= 0)
                  if (selection.start >= 0) {
                    // 在光标所在位置插入
                    newText = text.replaceRange(selection.start, selection.end, emoji);
                    newCursorPosition = selection.start + emoji.length;
                  } else {
                    // 如果没有焦点，直接加在末尾
                    newText = text + emoji;
                    newCursorPosition = newText.length;
                  }

                  _inputController.text = newText;

                  // 保持光标位置，并强制输入框获取焦点
                  _inputController.selection = TextSelection.collapsed(offset: newCursorPosition);

                  _toggleEmojiPicker(); // 选完关闭
                  FocusScope.of(context).requestFocus(FocusNode());
                },
              ),
            ),
          ),
        ],
      ),
    );
  }
}
