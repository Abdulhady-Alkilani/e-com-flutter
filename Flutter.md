# دليل شامل لإنشاء تطبيق Flutter باستخدام Laravel API و Provider

هذا المستند موجه للمبرمج (أو الـ AI Agent) المسؤول عن بناء تطبيق الهاتف (Flutter) المرتبط بخدمات الـ Backend (Laravel) الخاصة بمتجرنا الإلكتروني.

يعتمد هذا الدليل بشكل أساسي على استخدام إطار عمل **Flutter** لتطوير الواجهات، ومكتبة **Provider** لإدارة الحالة (State Management)، مع الاعتماد على **http** أو **dio** للاتصال بالـ API.

---

## 🧭 1. المعمارية وإدارة الحالة (Architecture & State Management)

نظراً لاستخدام **Provider**، يُنصح بشدة باتباع معمارية واضحة تفصل واجهة المستخدم (UI) عن منطق الأعمال (Business Logic):

- **Models:** كلاسات لتمثيل البيانات القادمة من הـ API (مثل `User`, `Product`, `CartItem`, `Order`).
- **Services (API Providers):** كلاسات مسؤولة حصرياً عن عملية الـ HTTP Requests ومعالجة استجابة الخادم وتمرير الـ Token (مثل `AuthService`, `ProductService`).
- **Providers (ChangeNotifier):** كلاسات مسؤولة عن حمل البيانات (State)، التفاعل مع الـ Services، وإبلاغ الواجهات بالتحديثات عبر `notifyListeners()`.
- **Views (UI):** شاشات التطبيق التي تستمع للتغيرات في الـ Providers باستخدام `Consumer` أو `context.watch()`.

---

## 🔒 2. المصادقة (Authentication Flow)

يعتمد النظام على **Laravel Sanctum**. يجب على تطبيق الهاتف إرسال **Bearer Token** في هيدر (Header) جميع الطلبات المحمية.

### الروابط (Endpoints)
- **Base URL:** `http://127.0.0.1:8000/api` (استبدل هذا برابط الخادم عند الرفع).
- **Headers المطلوبة دائماً:** 
  ```json
  {
    "Accept": "application/json",
    "Content-Type": "application/json" // في حال لم يكن الطلب يحتوي على ملفات
  }
  ```

#### 1. إنشاء حساب (Register)
- **POST** `/register`
- **Body:** `name`, `email`, `phone`, `password`, `password_confirmation`.
- **Flow:** بعد النجاح (Status 201)، سيتم إرسال كود OTP إلى إيميل المستخدم. يجب توجيه المستخدم لشاشة إدخال رمز التحقق.

#### 2. التحقق من الإيميل (Verify Email)
- **POST** `/verify-email`
- **Body:** `email`, `code`.
- **Flow:** بعد نجاح التحقق (Status 200)، يمكن توجيه المستخدم لشاشة تسجيل الدخول.

#### 3. تسجيل الدخول (Login)
- **POST** `/login`
- **Body:** `email`, `password`.
- **Response:** يعيد الكائن `user` بالإضافة إلى `token`.
- **Flow في Flutter:** 
  - يجب تخزين الـ `token` محلياً باستخدام `shared_preferences` أو `flutter_secure_storage`.
  - تحديث الـ `AuthProvider` ليصبح `isAuthenticated = true` وحفظ بيانات الـ `user`.

#### 4. تسجيل الخروج (Logout)
- **POST** `/logout`
- **Headers:** `Authorization: Bearer {token}`
- **Flow:** حذف الـ token المحلي، تفريغ الـ Providers، وتوجيه المستخدم لشاشة الدخول.

---

## 📦 3. النماذج الأساسية (Core Models & Providers)

### أ. المنتجات و الأقسام (Products)

- **GET** `/products` (يدعم `category_id` و `search` كـ Query Parameters)
- **GET** `/products/{id}`

**الفكرة في Flutter:**
إنشاء `ProductProvider` يحتوي على قائمة `List<Product> products = []`. يمتلك دالة `fetchProducts()` تقوم بطلب الـ API وتحديث القائمة والتنبيه بـ `notifyListeners()`. 
**تنويه:** المنتجات متوفرة للزوار غير مسجلي الدخول (Unauthenticated).

---

### ب. المفضلة (Favorites)
*(تتطلب Bearer Token)*

- **GET** `/favorites` (لجلب القائمة).
- **POST** `/favorites` (Body: `product_id`).
- **DELETE** `/favorites/{product_id}`.

**الفكرة في Flutter:**
إنشاء `FavoriteProvider` يهتم بجلب المنتجات المفضلة. عند عرض قائمة المنتجات الرئيسية، يمكن فحص ما إذا كان الـ `product.id` موجوداً ضمن قائمة الـ `FavoriteProvider` لتلوين أيقونة القلب ❤️.

---

### ج. سلة المشتريات (Cart)
*(تتطلب Bearer Token)*

- **GET** `/cart`
- **POST** `/cart` (Body: `product_id`, `quantity`)
- **PUT** `/cart/{cart_item_id}` (Body: `quantity`) للتعديل على الكمية.
- **DELETE** `/cart/{cart_item_id}` للحذف من السلة.

**الفكرة في Flutter:**
إنشاء `CartProvider`. يجب أن يحتوي على منطق لحساب السعر الإجمالي `totalPrice` محلياً لسرعة العرض، مع مزامنة العمليات (إضافة/حذف/تعديل وتحديداً `quantity`) مع الـ API لضمان التوافق الدائم.

---

### د. الطلبات وعملية الدفع (Orders & Checkout)
*(تتطلب Bearer Token)*

- **GET** `/orders` (عرض قائمة الطلبات السابقة للمستخدم).
- **GET** `/orders/{id}` (تفاصيل طلب معين).
- **POST** `/orders` (إنشاء الطلب النهائي ورفع إشعار الدفع).

**كيفية التعامل مع POST `/orders` في Flutter:**
بسبب الحاجة لرفع صورة (إشعار الدفع Sham Cash)، **لا نستخدم JSON Body** هنا. بدلاً من ذلك، نستخدم **MultipartRequest** عبر مكتبة `http` أو `FormData` في `dio`.

- الحقول المطلوبة (كـ `fields` نصية):
  - `shipping_address`
  - `shipping_phone`
  - `notes` (اختياري)
- الملف المطلوب (كـ `file`):
  - `payment_receipt_image`: يجب إرفاق الصورة الملتقطة من المعرض أو الكاميرا (بامتداد png/jpg وبحجم أقل من 5 ميجابايت).

*ملاحظة:* لنجاح عملية الـ Checkout يجب أن لا تكون السلة الخاصة بالمستخدم فارغة على الخادم. بمجرد نجاح الطلب، الخادم سيقوم بإنشاء الطلب وإفراغ السلة تلقائياً، لذا يجب على تطبيق Flutter عمل استدعاء لـ `cartProvider.clearCart()` بعد نجاح الطلب.

---

### هـ. إعدادات النظام (System Settings)
- **GET** `/settings`
- **Response:** يعيد الـ QR Code الخاص بـ Sham Cash ورقم جوال الأدمن للتواصل.
**الاستخدام:** يتم جلبها مرة واحدة عند إقلاع التطبيق وعرضها في شاشة الـ Checkout للمستخدم ليتمكن من مسح الـ QR وإجراء التحويل.

---

## 🛠 4. التعامل مع الأخطاء والخادم (Error Handling)

الـ API الخاصة بـ Laravel تقوم برد أخطاء من نوع **Validation Exceptions** بحالة `422 Unprocessable Entity`.

**شكل الاستجابة عند حدوث خطأ 422:**
```json
{
  "message": "The given data was invalid.",
  "errors": {
    "email": ["The email has already been taken."],
    "password": ["The password must be at least 8 characters."]
  }
}
```

**الإجراء في Flutter:**
يجب بناء دالة مركزية في الـ API Services لالتقاط الاستجابات بحالة `422` واستخراج الـ `errors` وعرضها لليوزر (مثلاً عبر `ScaffoldMessenger` SnackBar أو كنجوم حمراء تحت الـ TextFields).
في حال انتهاء صلاحية الـ Token (حالة `401 Unauthorized`)، يجب إجبار المستخدم على تسجيل الخروج التلقائي ونقله لشاشة تسجيل الدخول (`Navigator.pushReplacementNamed()`).

---

## 🚀 ملخص هيكل مبدئي لمجلدات Flutter المقترحة:

```text
lib/
 ├── main.dart
 ├── core/
 │    ├── api_client.dart       // إعدادات http/dio الرئيسية ومرفقات الـ Token
 │    └── constants.dart        // روابط الـ API والألوان
 ├── models/
 │    ├── user_model.dart
 │    ├── product_model.dart
 │    ├── cart_model.dart
 │    └── order_model.dart
 ├── providers/
 │    ├── auth_provider.dart
 │    ├── product_provider.dart
 │    ├── cart_provider.dart
 │    └── favorite_provider.dart
 └── ui/
      ├── screens/
      │    ├── auth/            // LoginScreen, RegisterScreen, VerifyOtpScreen
      │    ├── home/            // HomeScreen, ProductDetailsScreen
      │    ├── cart/            // CartScreen, CheckoutScreen
      │    └── profile/         // OrdersScreen
      └── widgets/              // Custom Button, Product Card, etc.
```

بهذا الدليل، يصبح الـ AI Agent أو مبرمج الـ Flutter قادراً على البدء الفوري ببناء التطبيق بشكل منظّم ومُهيأ للتكامل السليم مع الـ API الحالي.
