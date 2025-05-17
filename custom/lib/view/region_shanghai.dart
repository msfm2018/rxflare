// view/shanghai_customers.dart

import 'package:flutter/material.dart';
import 'package:rxflare/rxflare.dart';
import '../model/customer.dart';
import '../store/customer_store.dart';

class ShanghaiCustomerPage extends StatelessWidget {
  ShanghaiCustomerPage({super.key});

  final List<Customer> customers = [
    Customer(name: "张三", city: "上海", phone: "13800000001", region: "上海"),
    Customer(name: "李四", city: "上海", phone: "13800000002", region: "上海"),
    Customer(name: "王五", city: "上海", phone: "13800000003", region: "上海"),
  ];

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: ListView.builder(
            itemCount: customers.length,
            itemBuilder: (context, index) {
              final customer = customers[index];
              return ListTile(
                title: Text(customer.name),
                subtitle: Text(customer.phone),
                onTap: () => selectedCustomer.value = customer, //  更新 selectedCustomer
              );
            },
          ),
        ),
        Expanded(
          child: Rx(() {
            final customer = selectedCustomer.value; //  使用 selectedCustomer
            if (customer == null) {
              return const Center(child: Text("请选择客户"));
            }
            return Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                children: [
                  TextField(controller: TextEditingController(text: customer.name), decoration: const InputDecoration(labelText: "姓名"), onChanged: (v) => customer.name = v),
                  TextField(controller: TextEditingController(text: customer.phone), decoration: const InputDecoration(labelText: "电话"), onChanged: (v) => customer.phone = v),
                  const SizedBox(height: 10),
                  Text("城市：${customer.city}"),
                  Text("地区：${customer.region}"), //  显示地区
                ],
              ),
            );
          }),
        ),
      ],
    );
  }
}
