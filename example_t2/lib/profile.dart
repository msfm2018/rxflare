import 'package:flutter/material.dart';
import 'package:rxflare/rxflare.dart'; // 假设你的 rxr 别名定义在这里

class ProfilePage extends StatelessWidget {
  const ProfilePage({super.key});

  @override
  Widget build(BuildContext context) {
    // 获取当前页面的 pageId (调试用)
    final currentId = rxr.pageId();

    return Scaffold(
      appBar: AppBar(
        title: const Text("个人中心"),
        actions: [
          IconButton(
            icon: const Icon(Icons.settings),
            onPressed: () {
              // 跳转到设置页（假设你注册了 /setting）
              rxr.to("/setting");
            },
          ),
        ],
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            const SizedBox(height: 30),
            const CircleAvatar(radius: 50, child: Icon(Icons.person, size: 50)),
            const SizedBox(height: 16),
            const Text("Flutter 开发者", style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
            const Divider(height: 40),

            // 展示当前路由信息
            ListTile(leading: const Icon(Icons.info_outline), title: const Text("当前 PageID"), subtitle: Text(currentId ?? "未知")),

            ListTile(
              leading: const Icon(Icons.account_balance_wallet_outlined),
              title: const Text("我的钱包"),
              onTap: () {
                // 演示路径传参
                rxr.to("/detail/wallet?from=profile");
              },
            ),

            ListTile(
              leading: const Icon(Icons.exit_to_app, color: Colors.red),
              title: const Text("模拟注销 (返回根栈)", style: TextStyle(color: Colors.red)),
              onTap: () {
                // 这里的注销逻辑可以根据你的业务需求实现
                // 例如清空 tabPages 并切回第 0 个 Tab
                _showLogoutDialog(context);
              },
            ),
          ],
        ),
      ),
    );
  }

  void _showLogoutDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("提示"),
        content: const Text("确定要注销并返回登录吗？"),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text("取消")),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              // 跳转到登录页，逻辑可以根据 RxRouter 进一步扩展
              rxr.to("/login");
            },
            child: const Text("确定"),
          ),
        ],
      ),
    );
  }
}
