import 'dart:math' as math;

import 'package:material_ui/material_ui.dart';
import 'package:rxflare/rxflare.dart';

const int kTotal = 10000000;

class Item {
  final int id;
  final int count;
  const Item(this.id, this.count);
}

/// 模拟后端：有延迟，个别页第一次会失败，计数保存在"服务端"。
class FakeApi {
  final Map<int, int> counts = {};
  final Set<int> _failedOnce = {};

  Future<PageResult<Item>> fetch(int page, int size) async {
    await Future<void>.delayed(const Duration(milliseconds: 250));

    if (page % 17 == 3 && _failedOnce.add(page)) {
      throw Exception('模拟网络错误 (page $page)');
    }

    final start = page * size;
    final end = math.min(start + size, kTotal);
    return PageResult<Item>([
      for (var i = start; i < end; i++) Item(i, counts[i] ?? 0),
    ], totalCount: kTotal);
  }
}

final api = FakeApi();

final list = RxPagedList<Item>(
  loader: api.fetch,
  pageSize: 50,
  maxCachedPages: 20,
  prefetch: 1,
  initialTotalCount: kTotal, // 总数已知：启动即可确定滚动条长度
);

class PagedListDemo extends StatelessWidget {
  const PagedListDemo({super.key});

  @override
  Widget build(BuildContext context) {
    return Material(
      type: MaterialType.transparency,
      child: Rx(
        () => ListView.builder(
          itemCount: list.length,
          itemExtent: 64,
          itemBuilder: (_, i) => Row_(index: i),
        ),
      ),
    );
  }
}

class Row_ extends StatelessWidget {
  final int index;
  const Row_({super.key, required this.index});

  @override
  Widget build(BuildContext context) {
    // 每行自己的 Rx：只依赖第 index 项
    return Rx(() {
      final status = list.statusAt(index);
      final item = list[index];

      if (status == RxPageStatus.error) {
        return ListTile(
          title: Text('Item $index 加载失败'),
          subtitle: Text('${list.errorAt(index)}'),
          trailing: TextButton(
            onPressed: () => list.retryPage(index ~/ list.pageSize),
            child: const Text('重试'),
          ),
        );
      }

      if (item == null) {
        return const ListTile(
          title: _Bar(width: 140),
          subtitle: _Bar(width: 80),
        );
      }

      return ListTile(
        title: Text('Item ${item.id}'),
        subtitle: Text('Count: ${item.count}'),
        trailing: IconButton(
          icon: const Icon(Icons.add),
          onPressed: () {
            final next = item.count + 1;
            api.counts[item.id] = next; // 先写"后端"
            list.updateAt(item.id, Item(item.id, next)); // 再只刷新这一行
          },
        ),
      );
    });
  }
}

class _Bar extends StatelessWidget {
  final double width;
  const _Bar({required this.width});

  @override
  Widget build(BuildContext context) => Align(
    alignment: Alignment.centerLeft,
    child: Container(
      width: width,
      height: 12,
      decoration: BoxDecoration(
        color: Colors.grey.shade300,
        borderRadius: BorderRadius.circular(4),
      ),
    ),
  );
}
