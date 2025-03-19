


import 'package:isar/isar.dart';

part 'category_model.g.dart';

@Collection()
class Category {
  Id isid = Isar.autoIncrement;
  final String id;
  final String name;

  final String userId;

  Category({
    required this.id,
    required this.name,
  
    required this.userId,
    this.isid = Isar.autoIncrement,
  });

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      
      'userId': userId,
      'isid': isid,
    };
  }

  Category copyWith({
    String? id,
    String? name,
    String? type,
    String? userId,
  }) {
    return Category(
      id: id ?? this.id,
      name: name ?? this.name,
      
      userId: userId ?? this.userId,
    );
  }

  factory Category.fromMap(String id, Map<String, dynamic> map) {
    return Category(
      id: id,
      name: map['name'],
     
      userId: map['userId'],
      isid: map['isid'],
    );
  }
}