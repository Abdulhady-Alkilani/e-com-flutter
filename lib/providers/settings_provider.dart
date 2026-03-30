// lib/providers/settings_provider.dart
import 'package:flutter/foundation.dart';
import 'package:dio/dio.dart';
import '../core/api/api_client.dart';
import '../core/constants/api_constants.dart';

class SettingsProvider extends ChangeNotifier {
  final Dio _dio = ApiClient.instance.dio;

  String? _shamCashQr;
  String? _adminPhone;
  bool _isLoading = false;

  String? get shamCashQr => _shamCashQr;
  String? get adminPhone => _adminPhone;
  bool get isLoading => _isLoading;

  Future<void> fetchSettings() async {
    _isLoading = true;
    notifyListeners();
    try {
      final response = await _dio.get(ApiConstants.settings);
      final data = response.data['data'] as Map<String, dynamic>?;
      if (data != null) {
        _shamCashQr = data['sham_cash_qr'] as String?;
        _adminPhone = data['admin_phone'] as String?;
        notifyListeners();
      }
    } catch (_) {
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
}
