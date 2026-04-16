// lib/providers/product_provider.dart
import 'package:flutter/foundation.dart';
import 'package:dio/dio.dart';
import '../core/api/api_client.dart';
import '../core/constants/api_constants.dart';
import '../models/product_model.dart';
import '../models/category_model.dart';

class ProductProvider extends ChangeNotifier {
  final Dio _dio = ApiClient.instance.dio;

  List<ProductModel> _products = [];
  List<CategoryModel> _categories = [];
  bool _isLoading = false;
  String? _errorMessage;
  int _currentPage = 1;
  int _lastPage = 1;
  int? _selectedCategoryId;
  String? _searchQuery;

  List<ProductModel> get products => _products;
  List<CategoryModel> get categories => _categories;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  int get currentPage => _currentPage;
  int get lastPage => _lastPage;
  bool get hasNextPage => _currentPage < _lastPage;
  bool get hasPreviousPage => _currentPage > 1;
  int? get selectedCategoryId => _selectedCategoryId;

  void _setLoading(bool val) {
    _isLoading = val;
    notifyListeners();
  }

  Future<void> fetchCategories() async {
    try {
      final response = await _dio.get(ApiConstants.categories);
      final data = (response.data['data'] ?? response.data) as List;
      _categories =
          data.map((e) => CategoryModel.fromJson(e as Map<String, dynamic>)).toList();
      notifyListeners();
    } catch (e) {
      debugPrint('Categories Error: $e');
    }
  }

  Future<void> goToNextPage() async {
    if (hasNextPage) {
      _currentPage++;
      await fetchProducts(refresh: false);
    }
  }

  Future<void> goToPreviousPage() async {
    if (hasPreviousPage) {
      _currentPage--;
      await fetchProducts(refresh: false);
    }
  }

  Future<void> fetchProducts({bool refresh = false}) async {
    if (refresh) {
      _currentPage = 1;
      _products = [];
    }
    if (_isLoading) return;
    _setLoading(true);
    _errorMessage = null;
    try {
      final params = <String, dynamic>{'page': _currentPage};
      if (_selectedCategoryId != null) {
        params['category_id'] = _selectedCategoryId;
      }
      if (_searchQuery != null && _searchQuery!.isNotEmpty) {
        params['search'] = _searchQuery;
      }

      final response = await _dio.get(ApiConstants.products,
          queryParameters: params);
      final data = response.data['data'] as List;
      final pagination =
          response.data['pagination'] as Map<String, dynamic>?;

      _products =
          data.map((e) => ProductModel.fromJson(e as Map<String, dynamic>)).toList();
      _lastPage = pagination?['last_page'] as int? ?? 1;
      notifyListeners();
    } on DioException catch (e) {
      _errorMessage = e.message;
      notifyListeners();
    } catch (e) {
      _errorMessage = e.toString();
      debugPrint('Products API Error: $e');
      notifyListeners();
    } finally {
      _setLoading(false);
    }
  }

  Future<ProductModel?> fetchProductDetails(int productId) async {
    try {
      final response =
          await _dio.get('${ApiConstants.products}/$productId');
      final data = response.data['data'] as Map<String, dynamic>;
      return ProductModel.fromJson(data);
    } catch (_) {
      return null;
    }
  }

  void filterByCategory(int? categoryId) {
    _selectedCategoryId = categoryId;
    fetchProducts(refresh: true);
  }

  void search(String query) {
    _searchQuery = query;
    fetchProducts(refresh: true);
  }
}
