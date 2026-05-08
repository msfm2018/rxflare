import 'package:rxflare/rxflare.dart';
import '../models/menu_item.dart';

class CartController {
  // 🧱 响应式购物车列表
  final RxList<MenuItem> cartItems = RxList<MenuItem>([]);

  // 🔥 计算属性（替代 stream）
  late final RxComputed<double> totalPrice = computed(() {
    return cartItems.value.fold<double>(
      0.0,
      (sum, item) => sum + item.price,
    );
  });

  // 🛒 添加
  void addToCart(MenuItem item) {
    cartItems.add(item);
  }

  // ❌ 移除
  void removeFromCart(MenuItem item) {
    cartItems.remove(item);
  }

  // 🧹 清空
  void clearCart() {
    cartItems.value.clear();
  }

  // 📦 数量
  int get itemCount => cartItems.length;
}

// 单例
final cartController = CartController();