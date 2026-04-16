// lib/models/cart_model.dart

import '../core/constants/api_constants.dart';

class CartItemProduct {
  final int id;
  final String name;
  final double price;
  final String? mainImage;

  CartItemProduct({
    required this.id,
    required this.name,
    required this.price,
    this.mainImage,
  });

  factory CartItemProduct.fromJson(Map<String, dynamic> json) {
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

    return CartItemProduct(
      id: json['id'] as int,
      name: json['name'] as String,
      price: double.tryParse(json['price'].toString()) ?? 0.0,
      mainImage: sanitizeUrl(json['main_image'] as String?),
    );
  }
}

class CartItemModel {
  final int cartItemId;
  final CartItemProduct product;
  int quantity;

  CartItemModel({
    required this.cartItemId,
    required this.product,
    required this.quantity,
  });

  double get subtotal => product.price * quantity;

  factory CartItemModel.fromJson(Map<String, dynamic> json) {
    return CartItemModel(
      cartItemId: (json['id'] ?? json['cart_item_id']) as int,
      product: CartItemProduct.fromJson(
        json['product'] as Map<String, dynamic>,
      ),
      quantity: json['quantity'] as int,
    );
  }
}

class CartModel {
  final int cartId;
  final double totalPrice;
  final List<CartItemModel> items;

  CartModel({
    required this.cartId,
    required this.totalPrice,
    required this.items,
  });

  factory CartModel.fromJson(Map<String, dynamic> json) {
    final data = json['data'] as Map<String, dynamic>? ?? json;
    final itemsList = data['items'] as List<dynamic>? ?? [];
    return CartModel(
      cartId: data['cart_id'] as int? ?? 0,
      totalPrice:
          double.tryParse(data['total_price'].toString()) ?? 0.0,
      items: itemsList
          .map((e) => CartItemModel.fromJson(e as Map<String, dynamic>))
          .toList(),
    );
  }
}
