// lib/providers/product_provider.dart
import 'package:flutter/foundation.dart';
import 'package:dio/dio.dart';
import '../core/api/api_client.dart';
import '../core/constants/api_constants.dart';
import '../models/product_model.dart';
import '../models/category_model.dart';

class FilterOptions {
  final double? minPrice;
  final double? maxPrice;
  final bool? inStock;
  final String sortBy;
  final String sortOrder;
  final int? categoryId;

  FilterOptions({
    this.minPrice,
    this.maxPrice,
    this.inStock,
    this.sortBy = 'created_at',
    this.sortOrder = 'desc',
    this.categoryId,
  });
}

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

  // Filter & Sort state
  double? _minPrice;
  double? _maxPrice;
  bool? _inStockOnly;
  String _sortBy = 'created_at';
  String _sortOrder = 'desc';

  List<ProductModel> get products => _products;
  List<CategoryModel> get categories => _categories;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  int get currentPage => _currentPage;
  int get lastPage => _lastPage;
  bool get hasNextPage => _currentPage < _lastPage;
  bool get hasPreviousPage => _currentPage > 1;
  int? get selectedCategoryId => _selectedCategoryId;
  String get sortBy => _sortBy;
  String get sortOrder => _sortOrder;
  double? get minPrice => _minPrice;
  double? get maxPrice => _maxPrice;
  bool? get inStockOnly => _inStockOnly;

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
      if (_minPrice != null) {
        params['min_price'] = _minPrice;
      }
      if (_maxPrice != null) {
        params['max_price'] = _maxPrice;
      }
      if (_inStockOnly == true) {
        params['in_stock'] = 'true';
      }
      if (_sortBy != 'created_at' || _sortOrder != 'desc') {
        params['sort_by'] = _sortBy;
        params['sort_order'] = _sortOrder;
      }

      final response = await _dio.get(ApiConstants.products,
          queryParameters: params);

      debugPrint('Products response type: ${response.data.runtimeType}');

      List<dynamic> data;
      final rawData = response.data['data'];
      if (rawData is List) {
        data = rawData;
      } else if (rawData is Map) {
        data = rawData['data'] as List? ?? [];
      } else {
        data = (response.data is List ? response.data as List : []);
      }

      final pagination =
          response.data['pagination'] as Map<String, dynamic>?;
      final meta = response.data['meta'] as Map<String, dynamic>?;
      final innerMeta =
          rawData is Map ? rawData['meta'] as Map<String, dynamic>? : null;

      _products = [];
      for (final e in data) {
        try {
          _products.add(ProductModel.fromJson(e as Map<String, dynamic>));
        } catch (err) {
          debugPrint('Error parsing product: $err');
        }
      }
      _lastPage = pagination?['last_page'] as int? ??
          meta?['last_page'] as int? ??
          innerMeta?['last_page'] as int? ??
          1;

      debugPrint('Products loaded: ${_products.length}, lastPage: $_lastPage');
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

  /// Apply advanced filter options
  void applyFilters(FilterOptions options) {
    _minPrice = options.minPrice;
    _maxPrice = options.maxPrice;
    _inStockOnly = options.inStock;
    _sortBy = options.sortBy;
    _sortOrder = options.sortOrder;
    if (options.categoryId != null) {
      _selectedCategoryId = options.categoryId;
    }
    fetchProducts(refresh: true);
  }

  /// Reset all filters to default
  void resetFilters() {
    _minPrice = null;
    _maxPrice = null;
    _inStockOnly = null;
    _sortBy = 'created_at';
    _sortOrder = 'desc';
    _selectedCategoryId = null;
    _searchQuery = null;
    fetchProducts(refresh: true);
  }
}
