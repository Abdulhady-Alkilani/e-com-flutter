// lib/providers/cart_provider.dart
import 'package:flutter/foundation.dart';
import 'package:dio/dio.dart';
import '../core/api/api_client.dart';
import '../core/constants/api_constants.dart';
import '../models/cart_model.dart';

class CartProvider extends ChangeNotifier {
  final Dio _dio = ApiClient.instance.dio;

  List<CartItemModel> _items = [];
  bool _isLoading = false;
  String? _errorMessage;

  List<CartItemModel> get items => _items;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  int get itemCount => _items.length;

  double get totalPrice =>
      _items.fold(0, (sum, item) => sum + item.subtotal);

  void _setLoading(bool val) {
    _isLoading = val;
    notifyListeners();
  }

  Future<void> fetchCart() async {
    _setLoading(true);
    try {
      final response = await _dio.get(ApiConstants.cart);
      final data = response.data['data'] as Map<String, dynamic>?;
      if (data != null) {
        final itemsList = data['items'] as List<dynamic>? ?? [];
        _items = itemsList
            .map((e) => CartItemModel.fromJson(e as Map<String, dynamic>))
            .toList();
        notifyListeners();
      }
    } catch (_) {
    } finally {
      _setLoading(false);
    }
  }

  Future<bool> addToCart(int productId, {int quantity = 1}) async {
    try {
      await _dio.post(ApiConstants.cart,
          data: {'product_id': productId, 'quantity': quantity});
      await fetchCart();
      return true;
    } on DioException catch (e) {
      // Handle 422 out-of-stock error explicitly
      final errors = e.response?.data?['errors'];
      if (e.response?.statusCode == 422 && errors != null) {
        if (errors['stock'] != null) {
          _errorMessage = 'المنتج غير متوفر في المخزون';
        } else if (errors['cart'] != null) {
          _errorMessage = 'السلة فارغة';
        } else {
          _errorMessage = 'خطأ في البيانات المدخلة';
        }
      } else {
        _errorMessage = e.message;
      }
      notifyListeners();
      return false;
    }
  }

  Future<bool> updateQuantity(int cartItemId, int quantity) async {
    try {
      await _dio.put('${ApiConstants.cart}/$cartItemId',
          data: {'quantity': quantity});
      // Update local state immediately for responsiveness
      final idx = _items.indexWhere((e) => e.cartItemId == cartItemId);
      if (idx != -1) {
        _items[idx].quantity = quantity;
        notifyListeners();
      }
      return true;
    } catch (_) {
      return false;
    }
  }

  Future<bool> removeItem(int cartItemId) async {
    try {
      await _dio.delete('${ApiConstants.cart}/$cartItemId');
      _items.removeWhere((e) => e.cartItemId == cartItemId);
      notifyListeners();
      return true;
    } catch (_) {
      return false;
    }
  }

  /// Called after successful order submission
  void clearLocalCart() {
    _items = [];
    notifyListeners();
  }
}
