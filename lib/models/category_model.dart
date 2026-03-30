// lib/models/category_model.dart

class CategoryModel {
  final int id;
  final String name;
  final String? image;
  final bool isActive;

  CategoryModel({
    required this.id,
    required this.name,
    this.image,
    this.isActive = true,
  });

  factory CategoryModel.fromJson(Map<String, dynamic> json) {
    return CategoryModel(
      id: json['id'] as int,
      name: json['name'] as String,
      image: json['image'] as String?,
      isActive: json['is_active'] == true || json['is_active'] == 1,
    );
  }
}
