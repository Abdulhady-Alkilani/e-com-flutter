// lib/models/product_model.dart

import '../core/constants/api_constants.dart';
import 'category_model.dart';

int _parseInt(dynamic value, [int fallback = 0]) {
  if (value is int) return value;
  if (value is String) return int.tryParse(value) ?? fallback;
  if (value is double) return value.toInt();
  return fallback;
}

class ProductSize {
  final String size;
  final int quantity;

  ProductSize({required this.size, required this.quantity});

  factory ProductSize.fromJson(Map<String, dynamic> json) {
    return ProductSize(
      size: json['size'].toString(),
      quantity: _parseInt(json['quantity']),
    );
  }

  bool get isAvailable => quantity > 0;
}

class ProductImage {
  final int id;
  final String imagePath;
  final String? color;

  ProductImage({required this.id, required this.imagePath, this.color});

  factory ProductImage.fromJson(Map<String, dynamic> json) {
    String rawPath = json['image_path'] as String? ?? '';
    if (rawPath.contains('localhost')) {
      rawPath = rawPath.replaceAll('localhost', ApiConstants.defaultIp);
    }
    if (rawPath.contains('127.0.0.1')) {
      rawPath = rawPath.replaceAll('127.0.0.1', ApiConstants.defaultIp);
    }
    if (rawPath.isNotEmpty && !rawPath.startsWith('http')) {
      rawPath =
          'http://${ApiConstants.defaultIp}:${ApiConstants.defaultPort}/storage/$rawPath';
    }
    return ProductImage(
      id: _parseInt(json['id']),
      imagePath: rawPath,
      color: json['color'] as String?,
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
  final bool inStock;
  final String? mainImage;
  final String? mainImageColor;
  final bool isActive;
  final List<ProductImage> images;
  final List<ProductSize>? sizes;
  final List<String>? colors;
  final CategoryModel? category;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  ProductModel({
    required this.id,
    this.categoryId,
    required this.name,
    this.description,
    required this.price,
    required this.stock,
    this.inStock = false,
    this.mainImage,
    this.mainImageColor,
    this.isActive = true,
    this.images = const [],
    this.sizes,
    this.colors,
    this.category,
    this.createdAt,
    this.updatedAt,
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

    List<ProductSize>? parsedSizes;
    if (json['sizes'] != null && json['sizes'] is List) {
      parsedSizes = (json['sizes'] as List).map((s) {
        if (s is Map<String, dynamic>) {
          return ProductSize.fromJson(s);
        } else {
          return ProductSize(size: s.toString(), quantity: 0);
        }
      }).toList();
    }

    CategoryModel? parsedCategory;
    if (json['category'] != null && json['category'] is Map) {
      parsedCategory =
          CategoryModel.fromJson(json['category'] as Map<String, dynamic>);
    }

    return ProductModel(
      id: _parseInt(json['id']),
      categoryId: json['category_id'] != null ? _parseInt(json['category_id']) : null,
      name: json['name'].toString(),
      description: json['description']?.toString(),
      price: double.tryParse(json['price'].toString()) ?? 0.0,
      stock: _parseInt(json['stock']),
      inStock: json['in_stock'] == true || json['in_stock'] == 1 || _parseInt(json['stock']) > 0,
      mainImage: sanitizeUrl(json['main_image']?.toString()),
      mainImageColor: json['main_image_color'] as String?,
      isActive: json['is_active'] == true || json['is_active'] == 1,
      images: imagesList
              ?.map((e) => ProductImage.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
      sizes: parsedSizes,
      colors: (json['colors'] as List<dynamic>?)
          ?.map((e) => e.toString())
          .toList(),
      category: parsedCategory,
      createdAt: json['created_at'] != null
          ? DateTime.tryParse(json['created_at'].toString())
          : null,
      updatedAt: json['updated_at'] != null
          ? DateTime.tryParse(json['updated_at'].toString())
          : null,
    );
  }

  bool get hasSizes => sizes != null && sizes!.isNotEmpty;

  bool get hasColors => colors != null && colors!.isNotEmpty;

  String? imageUrlForColor(String color) {
    if (mainImageColor == color && mainImage != null) return mainImage;
    final match = images.where((img) => img.color == color);
    return match.isNotEmpty ? match.first.imagePath : null;
  }

  List<ProductSize> get availableSizes =>
      sizes?.where((s) => s.isAvailable).toList() ?? [];
}
