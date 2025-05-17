// import 'package:flutter/material.dart';
// import 'package:rxflare/rxflare.dart';
// import '../model/customer.dart';
// import '../store/customer_store.dart';class VipCustomerPage extends StatelessWidget {
//   const VipCustomerPage({super.key});

//   static final List<Customer> vipList = [
//     Customer(id: 1, name: '张三', phone: '18812345678', type: 'VIP'),
//     Customer(id: 2, name: '李四', phone: '18987654321', type: 'VIP')
//   ];

//   @override
//   Widget build(BuildContext context) {
//     return Row(
//       children: [
//         Expanded(
//           flex: 1,
//           child: ListView.builder(
//             itemCount: vipList.length,
//             itemBuilder: (context, index) {
//               final customer = vipList[index];
//               return ListTile(
//                 title: Text(customer.name),
//                 subtitle: Text(customer.phone),
//                 onTap: () => selectedCustomer.value = customer,
//               );
//             },
//           ),
//         ),
//         const VerticalDivider(width: 1),
//         Expanded(
//           flex: 2,
//           child: Rx(() {
//             final c = selectedCustomer.value;
//             if (c == null) {
//               return const Center(child: Text('请选择一个客户'));
//             }

//             return Padding(
//               padding: const EdgeInsets.all(16.0),
//               child: Column(
//                 crossAxisAlignment: CrossAxisAlignment.start,
//                 children: [
//                   Text('姓名: ${c.name}', style: const TextStyle(fontSize: 20)),
//                   const SizedBox(height: 8),
//                   Text('电话: ${c.phone}'),
//                   const SizedBox(height: 8),
//                   Text('类型: ${c.type ?? "普通"}'),
//                   const SizedBox(height: 8),
//                   Text('城市: ${c.city ?? "未知"}'),
//                   const SizedBox(height: 8),
//                   Text('地区: ${c.region ?? "未知"}'), //  显示地区
//                 ],
//               ),
//             );
//           }),
//         ),
//       ],
//     );
//   }
// }

import 'package:flutter/material.dart';
import 'package:rxflare/rxflare.dart';
import '../model/customer.dart';
import '../store/customer_store.dart';

class VipCustomerPage extends StatelessWidget {
  const VipCustomerPage({super.key});

  static final List<Customer> vipList = [Customer(id: 1, name: '张三', phone: '18812345678', type: 'VIP'), Customer(id: 2, name: '李四', phone: '18987654321', type: 'VIP')];

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          flex: 1,
          child: ListView.builder(
            itemCount: vipList.length,
            itemBuilder: (context, index) {
              final customer = vipList[index];
              return ListTile(title: Text(customer.name), subtitle: Text(customer.phone), onTap: () => selectedCustomer.value = customer);
            },
          ),
        ),
        const VerticalDivider(width: 1),
        Expanded(
          flex: 2,
          child: Rx(() {
            final c = selectedCustomer.value;
            if (c == null) {
              return const Center(child: Text('请选择一个客户'));
            }

            return Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('姓名: ${c.name}', style: const TextStyle(fontSize: 20)),
                  const SizedBox(height: 8),
                  Text('电话: ${c.phone}'),
                  const SizedBox(height: 8),
                  Text('类型: ${c.type ?? "普通"}'),
                  const SizedBox(height: 8),
                  Text('城市: ${c.city ?? "未知"}'),
                  const SizedBox(height: 8),
                  Text('地区: ${c.region ?? "未知"}'), //  显示地区
                ],
              ),
            );
          }),
        ),
      ],
    );
  }
}
