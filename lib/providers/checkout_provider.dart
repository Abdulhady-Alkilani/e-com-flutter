// lib/providers/checkout_provider.dart
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:dio/dio.dart';
import 'package:image_picker/image_picker.dart';
import '../core/api/api_client.dart';
import '../core/constants/api_constants.dart';

class CheckoutProvider extends ChangeNotifier {
  final Dio _dio = ApiClient.instance.dio;
  final ImagePicker _picker = ImagePicker();

  File? _receiptImage;
  bool _isSubmitting = false;
  String? _errorMessage;

  File? get receiptImage => _receiptImage;
  bool get isSubmitting => _isSubmitting;
  String? get errorMessage => _errorMessage;

  Future<void> pickReceiptImage() async {
    final XFile? picked =
        await _picker.pickImage(source: ImageSource.gallery, imageQuality: 80);
    if (picked != null) {
      _receiptImage = File(picked.path);
      notifyListeners();
    }
  }

  Future<void> pickReceiptImageFromCamera() async {
    final XFile? picked = await _picker.pickImage(
        source: ImageSource.camera, imageQuality: 80);
    if (picked != null) {
      _receiptImage = File(picked.path);
      notifyListeners();
    }
  }

  /// Submits the order using multipart/form-data
  Future<bool> submitOrder({
    required String shippingAddress,
    required String shippingPhone,
    String? notes,
    required File receiptImage,
  }) async {
    _isSubmitting = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final fileName = receiptImage.path.split('/').last;
      final formData = FormData.fromMap({
        'shipping_address': shippingAddress,
        'shipping_phone': shippingPhone,
        if (notes != null && notes.isNotEmpty) 'notes': notes,
        'payment_receipt_image': await MultipartFile.fromFile(
          receiptImage.path,
          filename: fileName,
        ),
      });

      final response = await _dio.post(ApiConstants.orders, data: formData);
      return response.statusCode == 201;
    } on DioException catch (e) {
      if (e.response?.data != null) {
        _errorMessage = _extractError(e.response!.data);
      } else {
        _errorMessage = 'حدث خطأ أثناء إرسال الطلب';
      }
      notifyListeners();
      return false;
    } finally {
      _isSubmitting = false;
      notifyListeners();
    }
  }

  String _extractError(dynamic data) {
    if (data is Map) {
      final errors = data['errors'] as Map?;
      if (errors != null && errors.isNotEmpty) {
        final firstKey = errors.keys.first;
        final firstValue = errors[firstKey];
        if (firstValue is List && firstValue.isNotEmpty) {
          return firstValue.first.toString();
        }
      }
      return data['message']?.toString() ?? 'خطأ غير معروف';
    }
    return 'حدث خطأ أثناء إرسال الطلب';
  }

  void clearReceipt() {
    _receiptImage = null;
    notifyListeners();
  }
}
