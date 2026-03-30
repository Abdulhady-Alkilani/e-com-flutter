// lib/models/order_model.dart

class OrderItemModel {
  final int id;
  final String productName;
  final int quantity;
  final double price;

  OrderItemModel({
    required this.id,
    required this.productName,
    required this.quantity,
    required this.price,
  });

  factory OrderItemModel.fromJson(Map<String, dynamic> json) {
    return OrderItemModel(
      id: json['id'] as int,
      productName: json['product_name'] as String? ?? '',
      quantity: json['quantity'] as int,
      price: double.tryParse(json['price'].toString()) ?? 0.0,
    );
  }
}

class OrderModel {
  final int id;
  final double totalAmount;
  final String status;
  final String? shippingAddress;
  final String? shippingPhone;
  final String? notes;
  final String? paymentReceiptImage;
  final String? createdAt;
  final List<OrderItemModel> items;

  OrderModel({
    required this.id,
    required this.totalAmount,
    required this.status,
    this.shippingAddress,
    this.shippingPhone,
    this.notes,
    this.paymentReceiptImage,
    this.createdAt,
    this.items = const [],
  });

  String get statusArabic {
    switch (status) {
      case 'unpaid':
        return 'بانتظار الدفع';
      case 'paid':
        return 'مدفوع';
      case 'shipped':
        return 'قيد الشحن';
      case 'delivered':
        return 'تم التسليم';
      case 'cancelled':
        return 'ملغي';
      default:
        return status;
    }
  }

  factory OrderModel.fromJson(Map<String, dynamic> json) {
    final itemsList = json['items'] as List<dynamic>?;
    return OrderModel(
      id: json['id'] as int,
      totalAmount:
          double.tryParse(json['total_amount'].toString()) ?? 0.0,
      status: json['status'] as String? ?? 'unpaid',
      shippingAddress: json['shipping_address'] as String?,
      shippingPhone: json['shipping_phone'] as String?,
      notes: json['notes'] as String?,
      paymentReceiptImage: json['payment_receipt_image'] as String?,
      createdAt: json['created_at'] as String?,
      items: itemsList
              ?.map((e) =>
                  OrderItemModel.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
    );
  }
}
