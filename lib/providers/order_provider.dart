// lib/providers/order_provider.dart
import 'package:flutter/foundation.dart';
import 'package:dio/dio.dart';
import '../core/api/api_client.dart';
import '../core/constants/api_constants.dart';
import '../models/order_model.dart';

class OrderProvider extends ChangeNotifier {
  final Dio _dio = ApiClient.instance.dio;

  List<OrderModel> _orders = [];
  bool _isLoading = false;

  List<OrderModel> get orders => _orders;
  bool get isLoading => _isLoading;

  Future<void> fetchOrders() async {
    _isLoading = true;
    notifyListeners();
    try {
      final response = await _dio.get(ApiConstants.orders);
      final data = response.data['data'] as List? ?? [];
      _orders =
          data.map((e) => OrderModel.fromJson(e as Map<String, dynamic>)).toList();
      notifyListeners();
    } catch (_) {
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<OrderModel?> fetchOrderDetails(int orderId) async {
    try {
      final response = await _dio.get('${ApiConstants.orders}/$orderId');
      final data = response.data['data'] as Map<String, dynamic>;
      return OrderModel.fromJson(data);
    } catch (_) {
      return null;
    }
  }
}
