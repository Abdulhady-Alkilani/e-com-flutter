// lib/providers/auth_provider.dart
import 'package:flutter/foundation.dart';
import 'package:dio/dio.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../core/api/api_client.dart';
import '../core/constants/api_constants.dart';
import '../models/user_model.dart';

class AuthProvider extends ChangeNotifier {
  final Dio _dio = ApiClient.instance.dio;
  final FlutterSecureStorage _storage = const FlutterSecureStorage();

  UserModel? _currentUser;
  bool _isAuthenticated = false;
  bool _isLoading = false;
  String? _errorMessage;

  UserModel? get currentUser => _currentUser;
  bool get isAuthenticated => _isAuthenticated;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  void _setLoading(bool val) {
    _isLoading = val;
    notifyListeners();
  }

  void _setError(String? msg) {
    _errorMessage = msg;
    notifyListeners();
  }

  /// Check if user has a valid token on app startup
  Future<void> checkAuthStatus() async {
    final token = await _storage.read(key: 'auth_token');
    if (token == null) return;
    try {
      final response = await _dio.get(ApiConstants.me);
      if (response.statusCode == 200) {
        final data = response.data['data'] ?? response.data;
        _currentUser = UserModel.fromJson(data as Map<String, dynamic>);
        _isAuthenticated = true;
        notifyListeners();
      }
    } catch (_) {
      await _storage.delete(key: 'auth_token');
    }
  }

  /// Register new user
  Future<bool> register({
    required String name,
    required String email,
    required String phone,
    required String password,
    required String passwordConfirmation,
  }) async {
    _setLoading(true);
    _setError(null);
    try {
      await _dio.post(ApiConstants.register, data: {
        'name': name,
        'email': email,
        'phone': phone,
        'password': password,
        'password_confirmation': passwordConfirmation,
      });
      return true;
    } on DioException catch (e) {
      _setError(parseApiError(e.response?.data));
      return false;
    } finally {
      _setLoading(false);
    }
  }

  /// Verify OTP (email verification)
  Future<bool> verifyOtp(String email, String code) async {
    _setLoading(true);
    _setError(null);
    try {
      await _dio.post(ApiConstants.verifyEmail,
          data: {'email': email, 'code': code});
      return true;
    } on DioException catch (e) {
      _setError(parseApiError(e.response?.data));
      return false;
    } finally {
      _setLoading(false);
    }
  }

  /// Login user
  Future<bool> login(String email, String password) async {
    _setLoading(true);
    _setError(null);
    try {
      final response = await _dio.post(ApiConstants.login,
          data: {'email': email, 'password': password});
      final token = response.data['token'] as String;
      final userData = response.data['user'] as Map<String, dynamic>;

      await _storage.write(key: 'auth_token', value: token);

      _currentUser = UserModel.fromJson(userData);
      _isAuthenticated = true;
      notifyListeners();
      return true;
    } on DioException catch (e) {
      _setError(parseApiError(e.response?.data));
      return false;
    } finally {
      _setLoading(false);
    }
  }

  /// Logout user
  Future<void> logout() async {
    try {
      await _dio.post(ApiConstants.logout);
    } catch (_) {}
    await _storage.delete(key: 'auth_token');
    _currentUser = null;
    _isAuthenticated = false;
    notifyListeners();
  }
}
