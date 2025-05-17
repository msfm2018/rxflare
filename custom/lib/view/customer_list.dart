import 'package:flutter/material.dart';
import 'package:rxflare/rxflare.dart';

import '../services/api_service.dart';

// 使用 RxValue 管理生日列表状态
final birthdayListState = RxValue<List<Map<String, dynamic>>>([], name: "BirthdayListState");

final todayYifuList = RxValue<List<Map<String, dynamic>>>([]);

final detail = RxValue<List<Map<String, dynamic>>>([]);

class CustomerListPage extends StatefulWidget {
  const CustomerListPage({super.key});

  @override
  State<CustomerListPage> createState() => _CustomerListPageState();
}

class _CustomerListPageState extends State<CustomerListPage> {
  List<Map<String, dynamic>> todayList = [];
  final TextEditingController ticketCtrl = TextEditingController();

  @override
  void initState() {
    super.initState();
    //放入监听事件中
    RxSimpleEvent.putEventListen(1001, (eventID, data) {
      if (data is Map<String, dynamic> && data['code'] == 0 && data['data'] is List) {
        todayYifuList.value = List<Map<String, dynamic>>.from(data['data']);
      }
    });

    RxSimpleEvent.putEventListen(1002, (eventID, data) {
      if (data is Map<String, dynamic> && data['code'] == 0 && data['data'] is List) {
        detail.value = List<Map<String, dynamic>>.from(data['data']);
        print(detail.value.toString());
      }
    });

    //调用取衣接口
    ApiService.fetchTodayYifuInfo();
  }

  Widget _quickButton(String label) => Text(label);

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          flex: 2,
          child: Padding(
            padding: const EdgeInsets.all(8.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // 快捷取衣
                SizedBox(
                  width: double.infinity, // 让 SizedBox 尽可能撑满父容器的宽度
                  child: Card(
                    child: Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('快捷取衣', style: TextStyle(fontWeight: FontWeight.bold)),
                          Row(
                            children: [
                              Expanded(child: TextField(controller: ticketCtrl, decoration: InputDecoration(hintText: '输入票据号'))),
                              ElevatedButton(onPressed: () {}, child: Text('一键取衣')),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                SizedBox(height: 10),

                // 信息发送
                SizedBox(
                  width: double.infinity,
                  child: Card(
                    child: Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('信息发送', style: TextStyle(fontWeight: FontWeight.bold)),
                          Row(
                            children: [
                              Checkbox(value: true, onChanged: (_) {}),
                              Expanded(child: TextField(decoration: InputDecoration(hintText: '输入手机号'))),
                              ElevatedButton(onPressed: () {}, child: Text('发送')),
                            ],
                          ),
                          TextField(decoration: InputDecoration(hintText: '输入信息内容')),
                        ],
                      ),
                    ),
                  ),
                ),
                SizedBox(height: 10),

                Expanded(
                  child: SizedBox(
                    width: double.infinity,
                    child: Card(
                      child: Padding(
                        padding: const EdgeInsets.all(8.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [Text("今日生日", style: TextStyle(fontWeight: FontWeight.bold)), Expanded(child: _buildBirthdayList())],
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),

        // 右侧：常用业务、今日收衣、今日取衣
        Expanded(
          flex: 3,
          child: Padding(
            padding: const EdgeInsets.all(8.0),
            child: Column(
              children: [
                // 常用业务按钮
                SizedBox(
                  width: double.infinity,
                  child: Card(
                    child: Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceAround,
                        children: [_quickButton('收衣'), _quickButton('美团'), _quickButton('取衣'), _quickButton('办卡'), _quickButton('充值')],
                      ),
                    ),
                  ),
                ),
                SizedBox(height: 10),

                Expanded(
                  child: SizedBox(
                    width: double.infinity,
                    child: Card(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [Padding(padding: const EdgeInsets.all(8.0), child: Text('今日收衣', style: TextStyle(fontWeight: FontWeight.bold))), Expanded(child: buildTodayYifuTable())],
                      ),
                    ),
                  ),
                ),
                SizedBox(height: 10),

                Expanded(child: SizedBox(width: double.infinity, child: buildDataTable())),
                SizedBox(height: 10),

                // 今日取衣
                Expanded(
                  child: SizedBox(
                    width: double.infinity,
                    child: Card(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [Padding(padding: const EdgeInsets.all(8.0), child: Text('今日取衣', style: TextStyle(fontWeight: FontWeight.bold))), Expanded(child: Text("暂无"))],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  //使用方法一
  final birthdayListFuture = RxFuture<List<Map<String, dynamic>>>(
    ApiService.fetchUserInfo().then((response) {
      if (response != null && response['code'] == 0 && response['data'] is List) {
        return (response['data'] as List).map((item) {
          final birthdayParts = (item['birthday'] as String).split('/');
          final formattedBirthday = '${birthdayParts[0]}-${birthdayParts[1].padLeft(2, '0')}-${birthdayParts[2].padLeft(2, '0')}';
          return {'name': item['xm'] ?? '', 'phone': item['phone']?.toString() ?? '', 'birthday': formattedBirthday, 'age': item['age'] ?? 0};
        }).toList();
      } else {
        return [];
      }
    }),
  );

  Widget buildDataTable() {
    return Rx(() {
      final data = detail.value;

      if (data.isEmpty) {
        return Center(child: Text("暂无今日收衣数据"));
      }

      return SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: SingleChildScrollView(
          scrollDirection: Axis.vertical,
          child: DataTable(
            showCheckboxColumn: false,
            columns: const [
              DataColumn(label: Text('票号')), // pdid
              DataColumn(label: Text('衣物名称')), // name
              DataColumn(label: Text('挂衣号')), // guayihao
              DataColumn(label: Text('颜色')), // color
              DataColumn(label: Text('区域')), // region
              DataColumn(label: Text('服务类型')), // server
              DataColumn(label: Text('备注')), // memo
              DataColumn(label: Text('条码号')), // 条码号
            ],
            rows:
                data.map((item) {
                  return DataRow(
                    cells: [
                      DataCell(Text('${item['pdid'] ?? ''}')),
                      DataCell(Text('${item['name'] ?? ''}')),
                      DataCell(Text('${item['guayihao'] ?? ''}')),
                      DataCell(Text('${item['color'] ?? ''}')),
                      DataCell(Text('${item['region'] ?? ''}')),
                      DataCell(Text('${item['server'] ?? ''}')),
                      DataCell(Text('${item['memo'] ?? ''}')),
                      DataCell(Text('${item['条码号'] ?? ''}')),
                    ],
                    onSelectChanged: (_) {
                      final pdid = item['pdid'];
                      if (pdid != null) {
                        ApiService.yifuInfoDetail(pdid);
                      }
                    },
                  );
                }).toList(),
          ),
        ),
      );
    });
  }

  Widget _buildBirthdayList() {
    return Rx(() {
      final snapshot = birthdayListFuture.value;

      if (snapshot.connectionState == ConnectionState.waiting) {
        return const Center(child: CircularProgressIndicator()); // 加载中
      } else if (snapshot.hasError) {
        return Text("错误: ${snapshot.error}"); // 错误
      } else if (snapshot.hasData) {
        final dataList = snapshot.data!;
        if (dataList.isEmpty) {
          return const Text("暂无数据");
        }

        return SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: DataTable(
            showCheckboxColumn: false, // 移除复选框列
            columns: const [DataColumn(label: Text('姓名')), DataColumn(label: Text('电话')), DataColumn(label: Text('生日')), DataColumn(label: Text('年龄'))],
            rows:
                dataList.map((customer) {
                  return DataRow(
                    cells: [
                      DataCell(Text(customer['name'] ?? '')),
                      DataCell(Text(customer['phone'] ?? '')),
                      DataCell(Text(customer['birthday'] ?? '')),
                      DataCell(Text('${customer['age'] ?? ''}')),
                    ],
                  );
                }).toList(),
          ),
        );
      } else {
        return const Text("无数据");
      }
    });
  }

  Widget buildTodayYifuTable() {
    return Rx(() {
      final data = todayYifuList.value;

      if (data.isEmpty) {
        return Center(child: Text("暂无今日收衣数据"));
      }

      return SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: SingleChildScrollView(
          scrollDirection: Axis.vertical,
          child: DataTable(
            showCheckboxColumn: false, // 移除复选框列
            columns: const [
              DataColumn(label: Text('票号')),
              DataColumn(label: Text('客户')),
              DataColumn(label: Text('件数')),
              DataColumn(label: Text('电话')),
              DataColumn(label: Text('金额')),
              DataColumn(label: Text('支付状态')),
              DataColumn(label: Text('卡名')),
            ],
            rows:
                data.map((item) {
                  return DataRow(
                    cells: [
                      DataCell(Text('${item['pdid'] ?? ''}')),
                      DataCell(Text('${item['name'] ?? ''}')),
                      DataCell(Text('${item['count'] ?? ''}')),
                      DataCell(Text('${item['phone'] ?? ''}')),
                      DataCell(Text('${item['price'] ?? ''}')),
                      DataCell(Text('${item['payed'] ?? ''}')),
                      DataCell(Text('${item['cardname'] ?? ''}')),
                    ],
                    onSelectChanged: (_) {
                      final pdid = item['pdid'];
                      if (pdid != null) {
                        ApiService.yifuInfoDetail(pdid);
                      }
                    },
                  );
                }).toList(),
          ),
        ),
      );
    });
  }
}
