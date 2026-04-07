import 'package:flutter/material.dart';

class AppLocalizations {
  final Locale locale;
  AppLocalizations(this.locale);

  static AppLocalizations of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations)!;
  }

  static const LocalizationsDelegate<AppLocalizations> delegate = _AppLocalizationsDelegate();

  static final Map<String, Map<String, String>> _localizedValues = {
    'en': {
      'app_name': 'My Store',
      'home': 'Home',
      'favorites': 'Favorites',
      'cart': 'Cart',
      'profile': 'Profile',
      'my_orders': 'My Orders',
      'account_info': 'Account Info',
      'logout': 'Logout',
      'login': 'Login',
      'register': 'Create Account',
      'email': 'Email',
      'password': 'Password',
      'phone': 'Phone Number',
      'name': 'Full Name',
      'verify_otp': 'Verify Code',
      'add_to_cart': 'Add to Cart',
      'checkout': 'Checkout',
      'confirm_order': 'Confirm Order',
      'shipping_address': 'Shipping Address',
      'shipping_phone': 'Delivery Phone',
      'upload_receipt': 'Upload Payment Receipt',
      'server_error': 'Failed to connect to the server',
      'unauthorized': 'Session expired, please login again',
      'search_product': 'Search for a product...',
      'all': 'All',
      'no_products': 'No Products Found',
      'empty_favorites': 'Favorites list is empty',
      'empty_favorites_desc': 'Add products you like by tapping ❤️',
      'empty_cart': 'Cart is empty',
      'empty_cart_desc': 'Add some products to get started',
      'total': 'Total:',
      'buy_now': 'Buy Now',
      'delete': 'Delete',
      'welcome': 'Welcome to our store',
      'welcome_desc': 'Log in to access your account and orders',
      'close': 'Close',
      'edit_profile': 'Edit Profile',
      'change_language': 'Change Language',
      'english': 'English',
      'arabic': 'العربية',
      'save_changes': 'Save Changes',
      'password_confirm': 'Confirm Password',
      'update_success': 'Profile updated successfully',
      'passwords_dont_match': 'Passwords do not match',
      'must_login': 'You must be logged in',
      'network_settings': 'Network Settings',
      'dark_mode': 'Dark Mode',
      'select_image': 'Select Image',
      'gallery': 'Gallery',
      'camera': 'Camera',
      'currency': 'SYP',
      'added_to_cart_success': 'Added to cart ✓',
    },
    'ar': {
      'app_name': 'المتجر الإلكتروني',
      'home': 'الرئيسية',
      'favorites': 'المفضلة',
      'cart': 'السلة',
      'profile': 'حسابي',
      'my_orders': 'طلباتي',
      'account_info': 'معلومات الحساب',
      'logout': 'تسجيل الخروج',
      'login': 'تسجيل الدخول',
      'register': 'إنشاء حساب جديد',
      'email': 'البريد الإلكتروني',
      'password': 'كلمة المرور',
      'phone': 'رقم الجوال',
      'name': 'الاسم الكامل',
      'verify_otp': 'التحقق من الرمز',
      'add_to_cart': 'أضف للسلة',
      'checkout': 'إتمام الطلب',
      'confirm_order': 'تأكيد الطلب',
      'shipping_address': 'عنوان الشحن',
      'shipping_phone': 'جوال الاستلام',
      'upload_receipt': 'رفع إيصال الدفع',
      'server_error': 'حدث خطأ في الاتصال بالخادم',
      'unauthorized': 'انتهت صلاحية الجلسة، يرجى تسجيل الدخول',
      'search_product': 'ابحث عن منتج...',
      'all': 'الكل',
      'no_products': 'لا توجد منتجات',
      'empty_favorites': 'قائمة المفضلة فارغة',
      'empty_favorites_desc': 'أضف منتجات تعجبك بالضغط على ❤️',
      'empty_cart': 'السلة فارغة',
      'empty_cart_desc': 'أضف بعض المنتجات للبدء',
      'total': 'الإجمالي:',
      'buy_now': 'إتمام الطلب',
      'delete': 'حذف',
      'welcome': 'مرحباً بك في متجرنا',
      'welcome_desc': 'سجّل دخولك للوصول لحسابك وطلباتك',
      'close': 'إغلاق',
      'edit_profile': 'تعديل الملف الشخصي',
      'change_language': 'تغيير اللغة',
      'english': 'English',
      'arabic': 'العربية',
      'save_changes': 'حفظ التعديلات',
      'password_confirm': 'تأكيد كلمة المرور',
      'update_success': 'تم تحديث الملف الشخصي بنجاح',
      'passwords_dont_match': 'كلمات المرور غير متطابقة',
      'must_login': 'يجب تسجيل الدخول أولاً',
      'network_settings': 'إعدادات الشبكة',
      'dark_mode': 'الوضع الداكن',
      'select_image': 'اختر صورة',
      'gallery': 'المعرض',
      'camera': 'الكاميرا',
      'currency': 'ل.س',
      'added_to_cart_success': 'تمت الإضافة إلى السلة ✓',
    },
  };

  String get(String key) {
    return _localizedValues[locale.languageCode]?[key] ?? key;
  }
}

class _AppLocalizationsDelegate extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  bool isSupported(Locale locale) => ['en', 'ar'].contains(locale.languageCode);

  @override
  Future<AppLocalizations> load(Locale locale) async {
    return AppLocalizations(locale);
  }

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

extension AppLocalizationsContext on BuildContext {
  String tr(String key) => AppLocalizations.of(this).get(key);
}
