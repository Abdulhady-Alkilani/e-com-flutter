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

  int _currentPage = 1;
  int _lastPage = 1;

  int get currentPage => _currentPage;
  int get lastPage => _lastPage;
  bool get hasNextPage => _currentPage < _lastPage;
  bool get hasPreviousPage => _currentPage > 1;

  Future<void> fetchOrders({bool refresh = false}) async {
    if (refresh) {
      _currentPage = 1;
      _orders = [];
    }
    if (_isLoading) return;
    _isLoading = true;
    notifyListeners();
    try {
      final response = await _dio.get(ApiConstants.orders, queryParameters: {'page': _currentPage});
      final data = response.data['data'] as List? ?? [];
      final pagination = response.data['pagination'] as Map<String, dynamic>?;

      _orders =
          data.map((e) => OrderModel.fromJson(e as Map<String, dynamic>)).toList();
      _lastPage = pagination?['last_page'] as int? ?? 1;
      notifyListeners();
    } catch (_) {
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> goToNextPage() async {
    if (hasNextPage) {
      _currentPage++;
      await fetchOrders(refresh: false);
    }
  }

  Future<void> goToPreviousPage() async {
    if (hasPreviousPage) {
      _currentPage--;
      await fetchOrders(refresh: false);
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
