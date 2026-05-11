import 'package:flutter/material.dart';
import 'package:rxflare/rxflare.dart';
import '../models/menu_item.dart';
import '../controllers/cart_controller.dart';
import 'cart_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final RxState<int> bottomNavIndex = RxState<int>(0);
  // 🧠 响应式状态：当前选中的分类索引
  final RxState<int> selectedCategoryIndex = RxState<int>(0);
  // 记录右侧当前选中的菜品索引
  final RxState<int> selectedProductIndex = RxState<int>(-1);
  // 分类数据
  final List<String> categories = ['热菜', '凉菜', '主食', '饮料', '甜点'];

  // 模拟菜单数据
  final menuItems = RxState<List<MenuItem>>([
    MenuItem(id: '1', name: '宫保鸡丁', category: '热菜', price: 38.0, imageUrl: '', description: '经典川菜'),
    MenuItem(id: '2', name: '麻婆豆腐', category: '热菜', price: 28.0, imageUrl: '', description: '麻辣鲜香'),
    MenuItem(id: '3', name: '拍黄瓜', category: '凉菜', price: 12.0, imageUrl: '', description: '清脆解腻'),
    MenuItem(id: '4', name: '可乐', category: '饮料', price: 8.0, imageUrl: '', description: '冰爽'),
  ]);

  @override
  Widget build(BuildContext context) {
    // 🧠 2. 联动：根据底栏索引决定 body 显示什么
    return RxBuilder(
      builder: (_) {
        return Scaffold(
          appBar: AppBar(
            title: Text(bottomNavIndex.value == 0 ? '点菜助手' : (bottomNavIndex.value == 1 ? '我的订单' : '个人中心')),
            actions: [if (bottomNavIndex.value == 0) _buildCartBadge(context)],
          ),

          // 🧠 核心：根据底栏索引切换内容主体
          body: IndexedStack(
            index: bottomNavIndex.value,
            children: [
              // 页面 0：点菜主页 (原来的 Row 布局)
              Row(
                children: [
                  _buildSideCategoryRail(),
                  Expanded(child: _buildProductList()),
                ],
              ),
              // 页面 1：订单页预览
              const Center(child: Text("订单列表页面")),
              // 页面 2：个人中心预览
              const Center(child: Text("个人中心页面")),
            ],
          ),

          // --- 底部：功能按钮栏 ---
          bottomNavigationBar: _buildBottomNavigationBar(),
        );
      },
    );
  }

  // 左侧分类栏
  Widget _buildSideCategoryRail() {
    return Container(
      width: 100,
      color: Colors.grey[100],
      child: ListView.builder(
        itemCount: categories.length,
        itemBuilder: (context, index) {
          // 🏆 核心修正：使用 Rx 包裹每一个具体的 Item
          // 这样当 selectedCategoryIndex 改变时，每个 Item 都能独立精准重绘
          return Rx(() {
            final isSelected = selectedCategoryIndex.value == index;

            return InkWell(
              onTap: () {
                selectedCategoryIndex.value = index;
              },
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 10),
                decoration: BoxDecoration(
                  // 颜色切换逻辑
                  color: isSelected ? Colors.white : Colors.transparent,
                  border: isSelected ? const Border(left: BorderSide(color: Colors.orange, width: 4)) : null,
                ),
                child: Text(
                  categories[index],
                  style: TextStyle(fontWeight: isSelected ? FontWeight.bold : FontWeight.normal, color: isSelected ? Colors.orange : Colors.black87),
                  textAlign: TextAlign.center,
                ),
              ),
            );
          });
        },
      ),
    );
  }

  Widget _buildProductList() {
    return RxBuilder(
      builder: (_) {
        // 1. 获取当前分类下的菜品
        final currentCategory = categories[selectedCategoryIndex.value];
        final items = menuItems.value.where((i) => i.category == currentCategory).toList();

        if (items.isEmpty) {
          return const Center(child: Text("该分类下暂无菜品"));
        }

        return ListView.builder(
          padding: const EdgeInsets.all(10),
          itemCount: items.length,
          itemBuilder: (context, index) {
            final item = items[index];

            // 🏆 核心：每一行都用 RxBuilder 包裹，实现精准变色
            return RxBuilder(
              builder: (context) {
                // 判断当前行是否被选中
                final isSelected = selectedProductIndex.value == index;

                return GestureDetector(
                  onTap: () {
                    // 点击时更新选中状态
                    selectedProductIndex.value = index;
                  },
                  child: Card(
                    //  选中变色：选中时为橘色背景，未选中时为白色
                    color: isSelected ? Colors.orange[50] : Colors.white,
                    elevation: isSelected ? 4 : 1,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                      //  选中时增加边框颜色
                      side: BorderSide(color: isSelected ? Colors.orange : Colors.transparent, width: 1),
                    ),
                    margin: const EdgeInsets.only(bottom: 10),
                    child: ListTile(
                      title: Text(
                        item.name,
                        style: TextStyle(fontWeight: isSelected ? FontWeight.bold : FontWeight.normal, color: isSelected ? Colors.orange[900] : Colors.black87),
                      ),
                      subtitle: Text('${item.price} 元'),
                      trailing: IconButton(
                        icon: Icon(Icons.add_circle, color: isSelected ? Colors.orange[700] : Colors.orange),
                        onPressed: () => cartController.addToCart(item),
                      ),
                    ),
                  ),
                );
              },
            );
          },
        );
      },
    );
  }

// 🧠 3. 修改底部导航：增加响应式监听和点击处理
  Widget _buildBottomNavigationBar() {
    return RxBuilder(
      builder: (_) {
        return BottomNavigationBar(
          selectedItemColor: Colors.orange,
          unselectedItemColor: Colors.grey,
          // 🏆 关键：绑定响应式状态
          currentIndex: bottomNavIndex.value,
          onTap: (index) {
            // 🏆 关键：点击时更新状态，触发 UI 变色和 body 切换
            bottomNavIndex.value = index;
          },
          items: const [
            BottomNavigationBarItem(icon: Icon(Icons.restaurant_menu), label: '点菜'),
            BottomNavigationBarItem(icon: Icon(Icons.receipt_long), label: '订单'),
            BottomNavigationBarItem(icon: Icon(Icons.person), label: '我的'),
          ],
        );
      },
    );
  }

  // 购物车图标
  Widget _buildCartBadge(BuildContext context) {
    return Stack(
      children: [
        IconButton(
          icon: const Icon(Icons.shopping_cart),
          onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const CartScreen())),
        ),
        Positioned(
          right: 8,
          top: 8,
          child: RxBuilder(
            builder: (_) => cartController.cartItems.isEmpty
                ? const SizedBox.shrink()
                : CircleAvatar(
                    radius: 8,
                    backgroundColor: Colors.red,
                    child: Text('${cartController.cartItems.length}', style: const TextStyle(fontSize: 10, color: Colors.white)),
                  ),
          ),
        ),
      ],
    );
  }
}
