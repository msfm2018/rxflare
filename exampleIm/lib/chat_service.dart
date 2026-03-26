import 'package:flutter/material.dart';
import 'package:rxflare/rxflare.dart';
import 'package:lpinyin/lpinyin.dart';

import 'entry.dart';

// 数据关系
// 👉allContacts 所有用户
// 👉 messagesMap = 全量聊天记录（数据库）
// 👉 chatList = 聊天摘要（列表UI）
// 👉 groupMembersMap = 群关系

class ChatService {
  final allContacts = [
    Contact(id: "u1", name: "王小静", avatar: "W", color: Colors.pink, type: "contacts", isStar: true),
    Contact(id: "u2", name: "张三", avatar: "Z", color: Colors.blue, type: "contacts"),
    Contact(id: "g1", name: "拳之森林会员群", avatar: "F", color: Colors.orange, type: "group_chats"),
    Contact(id: "s1", name: "文件传输助手", avatar: "文", color: Colors.green, type: "service"),
  ].obs;

  final messagesMap = {
    "s1": [Message(text: "[文件传输助手] 已连接，你可以发送文件到电脑", senderId: "s1", isMe: false, time: DateTime.now().millisecondsSinceEpoch - 86400000)].obs,
    "u1": [
      Message(text: "你好呀！", senderId: "u1", isMe: false, time: DateTime.now().millisecondsSinceEpoch - 3600000),
      Message(text: "最近在忙什么呢？", senderId: "u1", isMe: false, time: DateTime.now().millisecondsSinceEpoch - 3500000),
    ].obs,
    "u2": <Message>[].obs,
    "g1": [Message(text: "群公告：禁止发广告", senderId: "system", isMe: false, time: DateTime.now().millisecondsSinceEpoch - 10000)].obs,
  };

  final chatList = [
    ChatItem(id: "s1", type: "service", name: "文件传输助手", msg: "等待接收文件...", unread: 0, color: Colors.green, lastTime: DateTime.now().millisecondsSinceEpoch, isPinned: false),

    ChatItem(id: "g1", type: "group_chats", name: "拳之森林会员群", msg: "教练：下午有课", unread: 0, color: Colors.teal, lastTime: DateTime.now().millisecondsSinceEpoch - 2000, isPinned: false),
    ChatItem(id: "u1", type: "contact", name: "王小静", msg: "您好！", unread: 0, color: Colors.pinkAccent, lastTime: DateTime.now().millisecondsSinceEpoch - 3000, isPinned: false),
  ].obs;

  final groupMembersMap = {
    "g1": ["u1", "u2", "me"].obs,
  };

  final contactCategories = [
    ContactCategory(id: "new_friends", icon: Icons.person_add, name: "新的朋友", count: 0, color: Colors.orange),
    ContactCategory(id: "group_chats", icon: Icons.group, name: "群聊", count: 1, color: Colors.green),
    ContactCategory(id: "public_accounts", icon: Icons.campaign, name: "公众号", count: 13, color: Colors.blue),
    ContactCategory(id: "service_accounts", icon: Icons.business_center, name: "服务号", count: 19, color: Colors.blueAccent),
    ContactCategory(id: "enterprise_wechat", icon: Icons.corporate_fare, name: "企业微信联系人", count: 5, color: Colors.orangeAccent),
    ContactCategory(id: "contacts", icon: Icons.person, name: "联系人", count: 118, color: Colors.grey),
  ].obs;

  final selectedId = "s1".obs;
  //切换页面
  final selectedNavIndex = 1.obs;

  void sortChatList() {
    final List<ChatItem> newList = [...chatList.value];

    newList.sort((a, b) {
      // 置顶逻辑（如果取消注释，置顶项永远在最前）
      if (a.isPinned && !b.isPinned) return -1;
      if (!a.isPinned && b.isPinned) return 1;
      // 时间倒序：b - a
      return b.lastTime.compareTo(a.lastTime);
    });

    chatList.value = newList;
  }

  void togglePin(String id) {
    int idx = chatList.value.indexWhere((e) => e.id == id);
    if (idx == -1) return;

    final current = chatList.value[idx];

    chatList.updateField(idx, current.copyWith(isPinned: !current.isPinned));

    sortChatList();
  }

  //当前选中的通讯录分类 ID (默认为空)
  final selectedContactId = "".obs;

  final isContactsExpanded = false.obs; // 控制联系人项是否展开

  List<Map<String, dynamic>> getGroupedContacts(List<Contact> rawList) {
    // 1. 提取星标好友 (现在 e 是 Contact 对象，直接支持 .isStar)
    final stars = rawList.where((e) => e.isStar).toList();

    // 2. 提取普通好友并排序
    final regulars = rawList.where((e) => !e.isStar).toList();
    regulars.sort((a, b) {
      // ✅ 使用 lpinyin 库获取拼音
      String pinyinA = PinyinHelper.getShortPinyin(a.name).toUpperCase();
      String pinyinB = PinyinHelper.getShortPinyin(b.name).toUpperCase();
      return pinyinA.compareTo(pinyinB);
    });

    // 3. 构造带 UI 标签的最终列表
    // 注意：这里返回 List<Map> 是合理的，因为我们要混合 "header" 和 "contact" 两种类型
    List<Map<String, dynamic>> displayList = [];

    if (stars.isNotEmpty) {
      displayList.add({"type": "header", "label": "星标朋友", "icon": Icons.star_border});
      //  将 Contact 对象直接放入 Map
      displayList.addAll(stars.map((e) => {"type": "contact", "data": e}));
    }

    String? lastLetter;
    for (var contact in regulars) {
      String pinyin = PinyinHelper.getShortPinyin(contact.name);
      String currentLetter = pinyin.isNotEmpty ? pinyin[0].toUpperCase() : "#";

      // 如果首字母改变，插入一个字母标题行
      if (currentLetter != lastLetter) {
        displayList.add({"type": "header", "label": currentLetter});
        lastLetter = currentLetter;
      }
      // ✅ 包装成统一格式
      displayList.add({"type": "contact", "data": contact});
    }

    return displayList;
  }

  // 切换星标状态
  void toggleStar(String id) {
    int idx = allContacts.value.indexWhere((e) => e.id == id);
    if (idx == -1) return;

    // ✅ 自动获得代码提示：allContacts.value[idx].isStar
    final current = allContacts.value[idx];

    allContacts.updateField(idx, current.copyWith(isStar: !current.isStar));
  }

  void deleteContact(String id) {
    allContacts.value = allContacts.value.where((e) => e.id != id).toList();

    messagesMap.remove(id);

    chatList.value = chatList.value.where((e) => e.id != id).toList();

    // 4. 安全保护：如果当前删除的是正在选中的联系人，重置选中状态
    if (selectedId.value == id) {
      selectedId.value = ""; // 或者跳转回默认 ID 如 "s1"
    }
  }

  void deleteUiContact(String id) {
    messagesMap.remove(id);

    chatList.value = chatList.value.where((e) => e.id != id).toList();

    // 4. 安全保护：如果当前删除的是正在选中的联系人，重置选中状态
    if (selectedId.value == id) {
      selectedId.value = ""; // 或者跳转回默认 ID 如 "s1"
    }
  }

  void openChatWith(Contact contact) {
    selectedNavIndex.value = 1;
    final existingIndex = chatList.value.indexWhere((e) => e.id == contact.id);

    if (existingIndex == -1) {
      final newSession = ChatItem(
        id: contact.id,
        type: contact.type,
        name: contact.name,
        msg: "",
        unread: 0,
        color: contact.color,
        lastTime: DateTime.now().millisecondsSinceEpoch,
        isPinned: false,
      );
      chatList.value = [newSession, ...chatList.value];
    }

    if (!messagesMap.containsKey(contact.id)) {
      // ✅ 修复：补齐 senderId 参数
      messagesMap[contact.id] = RxValue<List<Message>>([
        Message(
          text: "你们已经成为好友，可以开始聊天了",
          senderId: "system", // 系统提示
          isMe: false,
          time: DateTime.now().millisecondsSinceEpoch,
        ),
      ]);
    }

    selectedId.value = contact.id;
  }

  // ✅ 新增：朋友圈响应式数据
  final momentsList = RxValue<List<Map<String, dynamic>>>([
    {
      "id": "m1",
      "userName": "张三",
      "avatar": "Z",
      "avatarColor": Colors.blue,
      "content": "今天在学习 Flutter，rxflare 真是太好用了！🚀",
      "images": ["https://picsum.photos/200", "https://picsum.photos/201"],
      "publishTime": DateTime.now().millisecondsSinceEpoch - 3600000,
      "likes": ["王小静", "李雷"],
      "comments": [
        {"from": "王小静", "content": "强啊，大佬！"},
      ],
    },
    {
      "id": "m2",
      "userName": "王小静",
      "avatar": "W",
      "avatarColor": Colors.pink,
      "content": "分享一首歌，下午好 ~",
      "images": [],
      "publishTime": DateTime.now().millisecondsSinceEpoch - 7200000,
      "likes": [],
      "comments": [],
    },
  ]);

  // ✅ 功能：点赞/取消点赞
  void toggleLike(String momentId, String currentUserName) {
    int idx = momentsList.value.indexWhere((m) => m["id"] == momentId);
    if (idx == -1) return;

    final moment = momentsList.value[idx];
    List<String> likes = List<String>.from(moment["likes"]);

    if (likes.contains(currentUserName)) {
      likes.remove(currentUserName);
    } else {
      likes.add(currentUserName);
    }

    // 使用 rxflare 更新局部字段
    momentsList.updateField(idx, {...moment, "likes": likes});
  }

  // ✅ 功能：发表评论
  void addComment(String momentId, String fromUser, String text) {
    int idx = momentsList.value.indexWhere((m) => m["id"] == momentId);
    if (idx == -1) return;

    final moment = momentsList.value[idx];
    List<Map<String, String>> comments = List<Map<String, String>>.from(moment["comments"]);

    comments.add({"from": fromUser, "content": text});

    momentsList.updateField(idx, {...moment, "comments": comments});
  }

  // ✅ 功能：发布新动态
  void postMoment(String content, List<String> images) {
    final newMoment = {
      "id": DateTime.now().millisecondsSinceEpoch.toString(),
      "userName": "我", // 实际应用中应从用户信息 Service 获取
      "avatar": "我",
      "avatarColor": Colors.orange,
      "content": content,
      "images": images,
      "publishTime": DateTime.now().millisecondsSinceEpoch,
      "likes": [],
      "comments": [],
    };

    // 插入到列表最前面
    momentsList.value = [newMoment, ...momentsList.value];
  }

  void startGroupChat(Contact baseContact, List<String> newSelectedIds) {
    // 1. 组合成员：我 + 原聊天对象 + 新选的人
    List<String> allMembers = ["me", baseContact.id, ...newSelectedIds];

    // 2. 随机生成群 ID
    final groupId = "g_${DateTime.now().millisecondsSinceEpoch}";

    // 3. 实例化一个新的 Contact
    // ✅ 修复：删掉 memberIds 参数，因为它在 Contact 类里不存在
    final newGroup = Contact(id: groupId, name: "${baseContact.name}、${newSelectedIds.length + 1}人的群聊", avatar: "群", color: Colors.blueGrey, type: "group_chats");

    // 4. ✅ 关键步骤：既然类里没字段，就必须存入你的 Map 中
    groupMembersMap[groupId] = RxValue(allMembers);

    // 5. 存入联系人列表
    allContacts.value = [...allContacts.value, newGroup];

    // 6. 跳转/打开
    openChatWith(newGroup);
  }

  void createGroupFromChat(String baseId, List<String> newIds) {
    // 1. 组建成员 ID 列表
    final members = ["me", baseId, ...newIds].toSet().toList();

    // 2. 生成群 ID
    final groupId = "g_${DateTime.now().millisecondsSinceEpoch}";

    final baseContact = allContacts.value.firstWhere((e) => e.id == baseId, orElse: () => allContacts.value.first);

    // 3. 实例化 Contact 对象
    // ✅ 修复：删掉 memberIds: members 参数，因为类里没定义
    final group = Contact(id: groupId, name: "${baseContact.name}、${newIds.length + 1}人的群聊", avatar: "群", color: Colors.teal, type: "group_chats");

    // 4. ✅ 核心：成员信息存入独立的 Map，实现解耦
    groupMembersMap[groupId] = RxValue(members);

    // 5. 初始化群消息
    String invitedNames = allContacts.value.where((c) => newIds.contains(c.id)).map((c) => c.name).join("、");

    // ✅ 修复：变量名统一使用 groupId，并补齐 senderId
    messagesMap[groupId] = RxValue<List<Message>>([Message(text: "你邀请了 $invitedNames 加入了群聊", senderId: "system", isMe: false, time: DateTime.now().millisecondsSinceEpoch)]);

    // 6. 更新联系人列表并跳转
    allContacts.value = [...allContacts.value, group];
    openChatWith(group);
  }
}
