import 'package:flutter/material.dart';

class PersonalCenterPage extends StatelessWidget {
  final List<String> shortcuts = ['会员充值', '收衣', '订单管理', '送洗', '回店', '上架', '营业日报', '取衣', '库存', '衣物追踪', '取衣密码', '加急衣物查询'];

  PersonalCenterPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('个人中心')),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 用户信息区域
            Row(
              children: [
                CircleAvatar(
                  radius: 40,
                  backgroundImage: NetworkImage('https://via.placeholder.com/150'), // 替换为实际用户头像URL
                ),
                SizedBox(width: 16),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '用户名', // 替换为实际用户名
                      style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                    ),
                    SizedBox(height: 4),
                    Text('用户ID: 123456'), // 替换为实际用户ID
                  ],
                ),
              ],
            ),
            SizedBox(height: 20),

            // 快捷方式
            Text('常用功能', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            SizedBox(height: 10),
            GridView.count(
              crossAxisCount: 4,
              shrinkWrap: true,
              physics: NeverScrollableScrollPhysics(),
              children:
                  shortcuts
                      .map(
                        (title) => Card(
                          child: InkWell(
                            onTap: () {
                              // 处理快捷方式点击事件
                              print('点击了 $title');
                              // 你可以在这里根据 title 执行相应的操作
                            },
                            child: Center(child: Padding(padding: const EdgeInsets.all(8.0), child: Text(title, textAlign: TextAlign.center))),
                          ),
                        ),
                      )
                      .toList(),
            ),
            SizedBox(height: 20),

            // 其他功能模块 (可以根据你的需求添加)
            Text('我的订单', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),

            // 在这里添加订单列表或相关操作
            SizedBox(height: 10),
            ListTile(
              leading: Icon(Icons.list_alt),
              title: Text('查看所有订单'),
              onTap: () {
                // 处理查看所有订单的逻辑
                print('查看所有订单');
              },
            ),

            SizedBox(height: 20),

            Text('账户设置', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            SizedBox(height: 10),
            ListTile(
              leading: Icon(Icons.settings),
              title: Text('修改密码'),
              onTap: () {
                // 处理修改密码的逻辑
                print('修改密码');
              },
            ),
            ListTile(
              leading: Icon(Icons.exit_to_app),
              title: Text('退出登录'),
              onTap: () {
                // 处理退出登录的逻辑
                print('退出登录');
              },
            ),
          ],
        ),
      ),
    );
  }
}
