// 轮询请求（RxFuture.poll 工厂 + 自带缓存
import 'package:flutter/material.dart';
import 'package:rxflare/rxflare.dart';

class PollController {
  final notice = <String>[].obs;
  // 新增：最后同步的时间戳
  final lastSyncTime = "".obs;

  late final pollFuture = RxFuture.poll((cancelToken) => pollNotice());

  Future<List<String>> pollNotice() async {
    await Future.delayed(const Duration(seconds: 1));
    final list = ["公告1", "公告2", "当前时间: ${DateTime.now()}"];

    // 更新数据
    notice.value = list;
    // 更新同步时间状态，这会触发所有监听该变量的 UI
    lastSyncTime.value = "${DateTime.now().hour}:${DateTime.now().minute}:${DateTime.now().second}";

    return list;
  }
}

class PollView extends StatefulWidget {
  const PollView({super.key});

  @override
  State<PollView> createState() => _PollViewState();
}

class _PollViewState extends State<PollView> {
  late PollController c;

  @override
  void initState() {
    super.initState();
    // 假设在 RxProvider 中注入的名字为 "pollx"
    c = RxDI.find<PollController>();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("轮询公告示例"),
        actions: [
          // 在 AppBar 显示一个静默刷新的指示器
          Rx(
            () => c.pollFuture.isRefreshing
                ? const Padding(
                    padding: EdgeInsets.symmetric(horizontal: 16),
                    child: SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2)),
                  )
                : const Icon(Icons.timer, color: Colors.green),
          ),
        ],
      ),
      body: Rx(() {
        // 1. 首次加载状态
        if (c.pollFuture.isInitialLoading) {
          return const Center(child: CircularProgressIndicator());
        }

        // 2. 错误处理（轮询某次失败）
        if (c.pollFuture.hasError && c.notice.value.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.error_outline, size: 48, color: Colors.red),
                Text("轮询连接失败: ${c.pollFuture.error}"),
                ElevatedButton(onPressed: () => c.pollFuture.retry(), child: const Text("手动重试")),
              ],
            ),
          );
        }

        final items = c.notice.value;

        return Column(
          children: [
            // 提示栏：显示下一次轮询的状态
            Container(
              padding: const EdgeInsets.all(8),
              color: Colors.blue.withValues(alpha: .1),
              child: Row(
                children: [
                  const Icon(Icons.info_outline, size: 16),
                  const SizedBox(width: 8),
                  Text("系统每 5 秒自动更新一次", style: Theme.of(context).textTheme.bodySmall),
                  const Spacer(),
                  // 直接监听 lastSyncTime
                  Rx(() => Text("最后同步: ${c.lastSyncTime.value}", style: Theme.of(context).textTheme.bodySmall)),
                ],
              ),
            ),

            Expanded(
              child: ListView.separated(
                padding: const EdgeInsets.all(16),
                itemCount: items.length,
                separatorBuilder: (_, __) => const Divider(),
                itemBuilder: (ctx, idx) {
                  return ListTile(
                    leading: const Icon(Icons.campaign, color: Colors.orange),
                    title: Text(items[idx]),
                    trailing: const Icon(Icons.chevron_right),
                  );
                },
              ),
            ),
          ],
        );
      }),
      // 允许用户手动立即刷新，且受防抖/节流保护
      floatingActionButton: FloatingActionButton(onPressed: () => c.pollFuture.refresh(force: true), child: const Icon(Icons.refresh)),
    );
  }
}

class PollPage extends StatelessWidget {
  const PollPage({super.key});

  @override
  Widget build(BuildContext context) {
    return RxProvider<PollController>(dependency: PollController(), child: const PollView());
  }
}
