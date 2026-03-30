// lib/providers/favorite_provider.dart
import 'package:flutter/foundation.dart';
import 'package:dio/dio.dart';
import '../core/api/api_client.dart';
import '../core/constants/api_constants.dart';
import '../models/product_model.dart';

class FavoriteProvider extends ChangeNotifier {
  final Dio _dio = ApiClient.instance.dio;

  List<ProductModel> _favorites = [];
  final Set<int> _favoriteIds = {};
  bool _isLoading = false;

  List<ProductModel> get favorites => _favorites;
  bool get isLoading => _isLoading;

  bool isFavorite(int productId) => _favoriteIds.contains(productId);

  Future<void> fetchFavorites() async {
    _isLoading = true;
    notifyListeners();
    try {
      final response = await _dio.get(ApiConstants.favorites);
      final data = response.data['data'] as List? ?? [];
      _favorites = data.map((e) {
        final item = e as Map<String, dynamic>;
        return ProductModel(
          id: item['product_id'] as int,
          name: item['name'] as String,
          price: 0,
          stock: 0,
          mainImage: item['main_image'] as String?,
        );
      }).toList();
      _favoriteIds.clear();
      for (final f in _favorites) {
        _favoriteIds.add(f.id);
      }
      notifyListeners();
    } catch (_) {
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> toggleFavorite(int productId) async {
    if (_favoriteIds.contains(productId)) {
      // Remove from favorites
      _favoriteIds.remove(productId);
      _favorites.removeWhere((e) => e.id == productId);
      notifyListeners();
      try {
        await _dio.delete('${ApiConstants.favorites}/$productId');
      } catch (_) {
        // Rollback on error
        _favoriteIds.add(productId);
        notifyListeners();
      }
    } else {
      // Add to favorites
      _favoriteIds.add(productId);
      notifyListeners();
      try {
        await _dio.post(ApiConstants.favorites,
            data: {'product_id': productId});
      } catch (_) {
        _favoriteIds.remove(productId);
        notifyListeners();
      }
    }
  }
}
