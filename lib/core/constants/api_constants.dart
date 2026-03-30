// lib/core/constants/api_constants.dart

class ApiConstants {
  // ─── Base Configuration ───────────────────────────────────────────────────
  static const String defaultIp = '10.140.183.183';
  static const String defaultPort = '8000';
  static String get baseUrl => 'http://$defaultIp:$defaultPort/api';

  // ─── Auth Endpoints ───────────────────────────────────────────────────────
  static const String register = '/register';
  static const String verifyEmail = '/verify-email';
  static const String login = '/login';
  static const String logout = '/logout';
  static const String me = '/me';

  // ─── Settings Endpoints ───────────────────────────────────────────────────
  static const String settings = '/settings';

  // ─── Products Endpoints ───────────────────────────────────────────────────
  static const String products = '/products';
  static const String categories = '/categories';

  // ─── Favorites Endpoints ──────────────────────────────────────────────────
  static const String favorites = '/favorites';

  // ─── Cart Endpoints ───────────────────────────────────────────────────────
  static const String cart = '/cart';

  // ─── Orders Endpoints ─────────────────────────────────────────────────────
  static const String orders = '/orders';
}

class AppStrings {
  AppStrings._();
  static const String appName = 'المتجر الإلكتروني';
  static const String login = 'تسجيل الدخول';
  static const String register = 'إنشاء حساب جديد';
  static const String email = 'البريد الإلكتروني';
  static const String password = 'كلمة المرور';
  static const String phone = 'رقم الجوال';
  static const String name = 'الاسم الكامل';
  static const String verifyOtp = 'التحقق من الرمز';
  static const String home = 'الرئيسية';
  static const String cart = 'السلة';
  static const String favorites = 'المفضلة';
  static const String profile = 'حسابي';
  static const String orders = 'طلباتي';
  static const String addToCart = 'أضف للسلة';
  static const String checkout = 'إتمام الطلب';
  static const String confirmOrder = 'تأكيد الطلب';
  static const String shippingAddress = 'عنوان الشحن';
  static const String shippingPhone = 'جوال الاستلام';
  static const String uploadReceipt = 'رفع إيصال الدفع';
  static const String serverError = 'حدث خطأ في الاتصال بالخادم';
  static const String unauthorized = 'انتهت صلاحية الجلسة، يرجى تسجيل الدخول';
}
