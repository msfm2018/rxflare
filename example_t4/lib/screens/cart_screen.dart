import 'package:flutter/material.dart';
import 'package:rxflare/rxflare.dart';
import '../controllers/cart_controller.dart';

class CartScreen extends StatelessWidget {
  const CartScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('购物车')),

      body: RxBuilder(
        builder: (context) {
          final items = cartController.cartItems;   // 自动追踪 RxList

          if (items.isEmpty) {
            return const Center(
              child: Text('购物车为空，快去点菜吧~', style: TextStyle(fontSize: 18)),
            );
          }

          return Column(
            children: [
              // 商品列表（只在 cartItems 变化时重建）
              Expanded(
                child: ListView.builder(
                  itemCount: items.length,
                  itemBuilder: (context, index) {
                    final item = items.value[index];

                    return ListTile(
                      title: Text(item.name),
                      subtitle: Text('${item.price.toStringAsFixed(2)} 元'),
                      trailing: IconButton(
                        icon: const Icon(Icons.delete, color: Colors.red),
                        onPressed: () {
                          cartController.removeFromCart(item);
                        },
                      ),
                    );
                  },
                ),
              ),

              // 总价（独立监听 totalPrice，粒度更细）
              RxBuilder(
                builder: (context) {
                  final total = cartController.totalPrice.value;   // 或 .value 根据你的实现
                  return Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Text(
                      '总计: ${total.toStringAsFixed(2)} 元',
                      style: const TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                        color: Colors.orange,
                      ),
                    ),
                  );
                },
              ),

              // 下单按钮
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
                child: SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      backgroundColor: Colors.green,
                    ),
                    onPressed: () {
                      showDialog(
                        context: context,
                        builder: (_) => AlertDialog(
                          title: const Text('下单成功 🎉'),
                          content: const Text('感谢您的点餐，预计30分钟送达！'),
                          actions: [
                            TextButton(
                              onPressed: () {
                                cartController.clearCart();
                                Navigator.popUntil(context, (route) => route.isFirst);
                              },
                              child: const Text('确定'),
                            ),
                          ],
                        ),
                      );
                    },
                    child: const Text(
                      '确认下单',
                      style: TextStyle(fontSize: 18),
                    ),
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}