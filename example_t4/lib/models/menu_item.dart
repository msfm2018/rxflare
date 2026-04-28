
class MenuItem {
  final String id;
  final String name;
  final String category; // 如：热菜、凉菜、主食、饮料
  final double price;
  final String imageUrl; // 图片 URL 或 assets 路径
  final String description;

  MenuItem({
    required this.id,
    required this.name,
    required this.category,
    required this.price,
    required this.imageUrl,
    required this.description,
  });

  MenuItem copyWith({int? quantity}) => this; // 购物车中可扩展数量
}