import 'package:flutter/material.dart';
import 'package:rxflare/rxflare.dart';
import 'login_auth.dart';

import 'chat_main_page.dart';
import 'chat_service.dart';
import 'login.dart';
import 'login_controller.dart';
import 'persistence_service.dart';

void main() {
// 1. 初始化你的页面表

  // rxr.to(0);
  RxDebug.isEnabled = false;

  // 注入服务
  RxDI.put(AuthService());
  // 2. 注入数据源 (ChatService)
  RxDI.put(ChatService());
  // RxDI.put(ChatService());
  // 3. 启动持久化服务（它一创建就会开始监听 messagesMap）
  RxDI.put(PersistenceService());
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      home: //RxRouterView()
          Rx(() {
        final auth = RxDI.find<AuthService>();
        if (auth.isLogin.value) {
          return const WeChatMainPage();
        } else {
          return getLoginPage();
        }
      }),
    );
  }
}

// 需要内存释放的 都放到 RxProvider 中
Widget getLoginPage() {
  return RxProvider<LoginController>(dependency: LoginController(), child: const LoginPage());
}

// class ChatService {
//   ChatService() {
//     _initPersistence();
//   }

//   void _initPersistence() {
//     int listenerCount = 0;
//     for (var entry in messagesMap.entries) {
//       listenerCount++;
//       entry.value.listen((newMsgs) {
//         if (newMsgs.isEmpty) return;
//         final chatId = entry.key;
//         final lastMsg = newMsgs.last;
//         print("【持久化】对话 $chatId 同步中：${lastMsg['text']}");
//         // 这里调用你的数据库代码：LocalDB.save(chatId, newMsgs);
//       });
//     }
//     print("【初始化】已开启 $listenerCount 个消息持久化监听器");
//   }
// }
