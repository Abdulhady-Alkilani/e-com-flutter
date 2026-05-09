// lib/models/category_model.dart

import '../core/constants/api_constants.dart';

class CategoryModel {
  final int id;
  final String name;
  final String? image;
  final bool isActive;
  final int productsCount;

  CategoryModel({
    required this.id,
    required this.name,
    this.image,
    this.isActive = true,
    this.productsCount = 0,
  });

  factory CategoryModel.fromJson(Map<String, dynamic> json) {
    String? sanitizeUrl(String? url) {
      if (url == null || url.isEmpty) return null;
      if (url.contains('localhost')) {
        return url.replaceAll('localhost', ApiConstants.defaultIp);
      }
      if (url.contains('127.0.0.1')) {
        return url.replaceAll('127.0.0.1', ApiConstants.defaultIp);
      }
      if (!url.startsWith('http')) {
        return 'http://${ApiConstants.defaultIp}:${ApiConstants.defaultPort}/storage/$url';
      }
      return url;
    }

    return CategoryModel(
      id: json['id'] as int,
      name: json['name'] as String,
      image: sanitizeUrl(json['image'] as String?),
      isActive: json['is_active'] == true || json['is_active'] == 1,
      productsCount: json['products_count'] as int? ?? 0,
    );
  }
}
