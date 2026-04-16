// lib/models/product_model.dart

import '../core/constants/api_constants.dart';

class ProductImage {
  final int id;
  final String imagePath;

  ProductImage({required this.id, required this.imagePath});

  factory ProductImage.fromJson(Map<String, dynamic> json) {
    return ProductImage(
      id: json['id'] as int,
      imagePath: json['image_path'] as String,
    );
  }
}

class ProductModel {
  final int id;
  final int? categoryId;
  final String name;
  final String? description;
  final double price;
  final int stock;
  final String? mainImage;
  final String? externalLink;
  final bool isActive;
  final List<ProductImage> images;

  ProductModel({
    required this.id,
    this.categoryId,
    required this.name,
    this.description,
    required this.price,
    required this.stock,
    this.mainImage,
    this.externalLink,
    this.isActive = true,
    this.images = const [],
  });

  factory ProductModel.fromJson(Map<String, dynamic> json) {
    final imagesList = json['images'] as List<dynamic>?;
    
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

    return ProductModel(
      id: json['id'] as int,
      categoryId: json['category_id'] as int?,
      name: json['name'] as String,
      description: json['description'] as String?,
      price: double.tryParse(json['price'].toString()) ?? 0.0,
      stock: json['stock'] as int? ?? 0,
      mainImage: sanitizeUrl(json['main_image'] as String?),
      externalLink: json['external_link'] as String?,
      isActive: json['is_active'] == true || json['is_active'] == 1,
      images: imagesList
              ?.map((e) => ProductImage.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
    );
  }
}
