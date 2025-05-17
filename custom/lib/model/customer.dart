class Customer {
  int? id;
  String name;
  String phone;
  String? type;
  String? city;
  String? region; //  添加 region 字段

  Customer({this.id, required this.name, required this.phone, this.type, this.city, this.region});
}
