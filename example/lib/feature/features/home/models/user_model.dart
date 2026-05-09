
// features/home/models/user_model.dart
class UserModel {
  final int id;
  final String name;
  final int age;
  final String? avatar;

  UserModel({
    required this.id,
    required this.name,
    required this.age,
    this.avatar,
  });

  /// 从 Map 转换为实体
  factory UserModel.fromMap(Map<String, dynamic> map) {
    return UserModel(
      id: map['id'] as int,
      name: map['name'] as String,
      age: map['age'] as int,
      avatar: map['avatar'] as String?,
    );
  }

  /// 转换为 Map（需要时使用）
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'age': age,
      'avatar': avatar,
    };
  }

  UserModel copyWith({
    int? id,
    String? name,
    int? age,
    String? avatar,
  }) {
    return UserModel(
      id: id ?? this.id,
      name: name ?? this.name,
      age: age ?? this.age,
      avatar: avatar ?? this.avatar,
    );
  }
}