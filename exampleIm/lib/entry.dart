import 'package:flutter/material.dart';

class User {
  final String id;
  final String name;
  final String avatar;

  User({required this.id, required this.name, required this.avatar});
}

class ChatItem {
  final String id;
  final String name;
  final String msg;
  final int unread;
  final Color color;
  final int lastTime;
  final bool isPinned;
  final String type; // ⭐ 别忘了这个

  ChatItem({required this.id, required this.name, required this.msg, required this.unread, required this.color, required this.lastTime, required this.isPinned, required this.type});

  ChatItem copyWith({String? msg, int? unread, bool? isPinned, int? lastTime}) {
    return ChatItem(
      id: id,
      name: name,
      type: type,
      color: color,
      msg: msg ?? this.msg,
      unread: unread ?? this.unread,
      isPinned: isPinned ?? this.isPinned,
      lastTime: lastTime ?? this.lastTime,
    );
  }
}

class Message {
  final String text;
  final String senderId; //  新增
  final bool isMe;
  final int time;
  final double? progress;

  Message({required this.text, required this.senderId, required this.isMe, required this.time, this.progress});

  Message copyWith({String? text, String? senderId, bool? isMe, int? time, double? progress}) {
    return Message(text: text ?? this.text, senderId: senderId ?? this.senderId, isMe: isMe ?? this.isMe, time: time ?? this.time, progress: progress ?? this.progress);
  }
}

class Contact {
  final String id; // 统一使用 uid 体系
  final String name;
  final String avatar;
  final Color color;
  final String type; // 'contacts', 'groupChats' 等
  final bool isStar; // 是否星标
  final bool isPinned; // 是否置顶（对应 chatList）

  Contact({required this.id, required this.name, required this.avatar, required this.color, required this.type, this.isStar = false, this.isPinned = false});

  // 用于 rxflare 局部更新
  Contact copyWith({bool? isStar, bool? isPinned, String? name, List<String>? memberIds}) {
    return Contact(id: id, name: name ?? this.name, avatar: avatar, color: color, type: type, isStar: isStar ?? this.isStar, isPinned: isPinned ?? this.isPinned);
  }
}

enum SessionType { contact, groupChats, service, publicAccounts }

class ChatSession {
  final String id;
  final String name;
  final String lastMsg;
  final int unread;
  final Color color;
  final int lastTime;
  final bool isPinned;
  final SessionType type; //  明确类型

  ChatSession({required this.id, required this.name, required this.lastMsg, required this.unread, required this.color, required this.lastTime, required this.isPinned, required this.type});

  // 方便 RxFlare 局部更新
  ChatSession copyWith({String? lastMsg, int? unread, bool? isPinned, int? lastTime}) {
    return ChatSession(
      id: id,
      name: name,
      color: color,
      type: type,
      lastMsg: lastMsg ?? this.lastMsg,
      unread: unread ?? this.unread,
      isPinned: isPinned ?? this.isPinned,
      lastTime: lastTime ?? this.lastTime,
    );
  }
}

class ContactCategory {
  final String id;
  final IconData icon;
  final String name;
  final int count;
  final Color color;

  ContactCategory({required this.id, required this.icon, required this.name, required this.count, required this.color});

  ContactCategory copyWith({String? id, IconData? icon, String? name, int? count, Color? color}) {
    return ContactCategory(id: id ?? this.id, icon: icon ?? this.icon, name: name ?? this.name, count: count ?? this.count, color: color ?? this.color);
  }
}
