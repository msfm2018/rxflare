import 'package:flutter/foundation.dart';
import 'package:rxflare/rxflare.dart';
import 'chat_service.dart';
import 'entry.dart';

class PersistenceService {
  // 1. 存储已监听的对话ID（防止重复监听）
  final Set<String> _activeIds = {};
  // 2. 存储监听取消函数（关键：用于释放资源）
  final Map<String, VoidCallback> _cancelTasks = {};

  PersistenceService() {
    try {
      final chatService = RxGet.find<ChatService>();
      // 初始化监听所有现有对话
      for (var entry in chatService.messagesMap.entries) {
        watch(entry.key, entry.value);
      }
      RxDebug.log("🚀 [持久化] 基础服务已启动，监听对话数: ${_activeIds.length}");
    } catch (e) {
      RxDebug.log("❌ [持久化] 服务启动失败: $e");
    }
  }

  /// 为指定对话开启消息持久化监听
  /// [chatId] 对话ID
  /// [msgsRx] 消息列表的响应式对象
void watch(String chatId, RxValue<List<Message>> msgsRx) {
    if (_activeIds.contains(chatId)) {
      RxDebug.log("⚠️ [持久化] 对话 $chatId 已开启监听，跳过");
      return;
    }

    try {
      _activeIds.add(chatId);
      
      final cancel = msgsRx.listen((newMsgs) {
        if (newMsgs.isEmpty) return;
        
        // 现在 lastMsg 是 Message 类型了
        final Message lastMsg = newMsgs.last; 
        
        // ✅ 这里的访问方式从 lastMsg['text'] 变成 lastMsg.text
        RxDebug.log("💾 [DB写入] 对话 $chatId -> 内容: ${lastMsg.text}");
      });

      _cancelTasks[chatId] = cancel;
      RxDebug.log("➕ [持久化] 开启监控: $chatId");
    } catch (e) {
      _activeIds.remove(chatId);
      RxDebug.log("❌ [持久化] 开启 $chatId 监听失败: $e");
    }
  }

  /// 手动取消单个对话的监听（可选扩展）
  void unwatch(String chatId) {
    if (_cancelTasks.containsKey(chatId)) {
      _cancelTasks[chatId]!(); // 执行取消函数
      _cancelTasks.remove(chatId);
      _activeIds.remove(chatId);
      RxDebug.log("➖ [持久化] 取消监控: $chatId");
    }
  }

  /// 释放所有资源（必须调用，如页面销毁时）
  void dispose() {
    // 遍历执行所有取消函数，真正释放监听器
    for (var cancelFunc in _cancelTasks.values) {
      cancelFunc();
    }
    // 清空缓存
    _activeIds.clear();
    _cancelTasks.clear();
    RxDebug.log("🗑️ [持久化] 所有监听器已注销，服务已停止");
  }
}