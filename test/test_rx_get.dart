定义一个 Controller (业务逻辑类)
我们将之前的 obs、computed、runAsync 全部封装进一个类里
class UserController {
  // 1. 状态定义
  final name = "访客".obs;
  final age = 18.obs;
  final isLoading = false.obs;

  // 2. 计算属性
  late final info = computed(() => "${name.value} (年龄: ${age.value})");

  // 3. 业务方法
  Future<void> refreshUser() async {
    await name.runAsync(
      () async {
        await Future.delayed(Duration(seconds: 1));
        return "高级玩家: 小明";
      },
      loadingState: isLoading,
    );
  }
}

// PageA.dart
class PageA extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return RxParent<UserController>(
      dependency: UserController(),
      name: "user_service", // 👈 给这个实例贴上“名字标签”
      child: Scaffold(
        appBar: AppBar(title: Text("个人中心")),
        body: Center(
          child: ElevatedButton(
            onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => PageB())),
            child: Text("去页面 B (解耦模式)"),
          ),
        ),
      ),
    );
  }
}

// PageB.dart 
// 💡 注意：这里没有任何关于 UserController 的 import！

class PageB extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    // 1. 根据名字查找，返回类型为 dynamic
    final dynamic user = RxObjMgr.find(name: "user_service");

    return Scaffold(
      appBar: AppBar(title: Text("设置页面")),
      body: Center(
        child: Column(
          children: [
            // 2. 直接访问 name.value (dynamic 会在运行时查找属性)
            Rx(() => Text("用户名: ${user.name.value}")),
            
            // 3. 访问计算属性 info.value
            Rx(() => Text("格式化信息: ${user.info.value}")),

            // 4. 调用异步方法
            ElevatedButton(
              onPressed: () => user.refreshUser(), 
              child: Rx(() => user.isLoading.value 
                ? CircularProgressIndicator() 
                : Text("刷新用户数据")),
            ),
          ],
        ),
      ),
    );
  }
}

同模块开发	RxObjMgr.find<UserController>()	有提示，最安全。
跨模块解耦	RxObjMgr.find(name: "user_service")	零依赖，适合插件化。
自动回收	RxParent(name: "user_service")	随页面销毁，不占内存。

放入 最顶层
void main() {
  runApp(
    RxParent<GlobalController>(
      dependency: GlobalController(),
      child: MaterialApp(home: HomePage()),
    ),
  );
}

模块,            功能,              对应代码
数据源,         基础响应式,           0.obs
处理工厂,         联动计算,           computed(() => ...)
异步引擎,       异步请求+重试+缓存,    runAsyncWithCache
渲染终端,       自动局部刷新,           Rx(() => ...)
中央仓库,       跨页面共享,             RxObjMgr.put / find


数据层：RxState + .obs (支持 int, String, Map, List 等)。

逻辑层：computed (智能计算) + runAsync (异步/重试/缓存)。

视图层：RxObx / Rx (局部精准刷新)。

注入层：RxObjMgr (单例/懒加载/自动回收)。