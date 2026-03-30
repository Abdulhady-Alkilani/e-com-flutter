# تقرير شامل للمشروع ودليل تكامل الـ API لتطبيق Flutter

هذا التقرير موجه خصيصاً للمبرمج أو الـ **AI Agent** المكلف ببناء تطبيق الهاتف الذكي (الواجهة الأمامية) باستخدام إطار عمل **Flutter** ومكتبة إدارة الحالة **Provider**. يحتوي التقرير على فهم كامل لهيكلية الواجهة الخلفية (Backend) المبنية بـ Laravel، وتفاصيل دقيقة لكل نقطة نهاية (Endpoint) في الـ API.

---

## 1. نظرة عامة على المشروع (Project Overview)

المشروع عبارة عن نظام متجر إلكتروني بنظام البائع الواحد (Single-Vendor E-Commerce).
- **التقنيات المستخدمة (Backend):** Laravel 12، FilamentPHP 3.3 (لوحتي تحكم Admin و Vendor)، Laravel Sanctum (للمصادقة)، وقواعد بيانات MySQL.
- **الفكرة المركزية:** سير عمل الدفع يعتمد على التحويل المالي اليدوي (عبر Sham Cash). يقوم المستخدم برفع صورة إشعار التحويل المالي (Receipt Image) عند تأكيد الطلب من خلال التطبيق.

---

## 2. هيكل البيانات الأساسي (Data Entities)

الكيانات التي ستحتاج لإنشاء **Models** لها في Flutter، وهي تتطابق مع الجداول في قاعدة البيانات:
- **User:** `id`, `name`, `email`, `phone`, `role` (admin/vendor/user), `avatar`.
- **Product:** `id`, `category_id`, `name`, `description`, `price`, `stock`, `main_image`, `external_link`, `is_active`.
- **Category:** `id`, `name`, `image`, `is_active`.
- **Cart & CartItem:** سلة المشتريات الخاصة بالمستخدم، مرتبطة بالمنتجات وتتضمن الـ `quantity`.
- **Order & OrderItem:** الطلبات النهائية وتشمل `total_amount`، الـ `status` (unpaid, paid, shipped, delivered) وصورة الإشعار `payment_receipt_image`.

---

## 3. إعدادات الـ API الأساسية (Core API Configuration)

- **رابط الخادم الأساسي (Base URL):** `http://{server_domain_or_ip}:8000/api`
- **التوثيق (Authentication):** نظام التوثيق يعتمد على **Bearer Token** عبر Laravel Sanctum.
- **التوصيات للـ AI Agent في Flutter:**
  - قم بإعداد `Dio` أو `http` كـ API Client مخصص.
  - قم بإضافة **Interceptors** لحقن الـ `Authorization: Bearer {token}` تلقائياً في كل الطلبات المحمية.
  - اضبط ترويسة الطلبات (Headers):
    ```json
    {
      "Accept": "application/json",
      "Content-Type": "application/json"
    }
    ```

---

## 4. تفاصيل الـ Endpoints وكيفية إدارتها بـ Provider

فيما يلي تفصيل لمسارات الـ API (البالغ عددها 19 مساراً) وكيفية عكس كل قسم في `Provider` مخصص داخل Flutter.

### القسم الأول: المصادقة (Auth API) 🔒 -> `AuthProvider`

1. **إنشاء حساب (Register)**
   - **المسار:** `POST /register`
   - **البيانات المطلوبة (Body):** `name`, `email`, `phone`, `password`, `password_confirmation`.
   - **سير العمل (Flow):** بعد نجاح الطلب (201 Created)، النظام سيرسل OTP عبر البريد الإلكتروني. يجب نقل المستخدم لشاشة `VerifyEmailScreen`.

2. **التحقق من البريد (Verify Email)**
   - **المسار:** `POST /verify-email`
   - **البيانات المطلوبة (Body):** `email`, `code` (كود الـ OTP).
   - **سير العمل:** بعد التحقق (200 OK)، قم بنقل المستخدم لشاشة `LoginScreen`.

3. **تسجيل الدخول (Login)**
   - **المسار:** `POST /login`
   - **البيانات المطلوبة (Body):** `email`, `password`.
   - **الاستجابة:** المخدم يعيد بيانات المستخدم مع الـ `token`.
   - **سير العمل في `AuthProvider`:**
     - حفظ الـ `token` باستخدام `flutter_secure_storage`.
     - تغيير حالة `isAuthenticated` لـ `true` وإشعار المستمعين (`notifyListeners`).

4. **بيانات المستخدم الحالي (Me) وتسجيل الخروج (Logout)** *(تتطلب Token)*
   - **المسارات:** `GET /me` (لجلب بيانات اليوزر) و `POST /logout` (لإتلاف الـ Token).
   - عند الـ Logout يجب تنظيف التوكن وتهيئة كل الـ Providers من جديد.

---

### القسم الثاني: الإعدادات العامة (Settings API) -> `SettingsProvider`

- **المسار:** `GET /settings`
- **الوظيفة:** يجلب إعدادات النظام، وتحديداً صورة QR Code الخاصة بحساب التدفق النقدي (مثل `sham_cash_qr`) ورقم التواصل.
- **الاستخدام في التطبيق:** جلب البيانات مرة واحدة في بدء تشغيل التطبيق (Splash/Init) وعرض صورة الـ QR بشكل بارز في نافذة الدفع (Checkout).

---

### القسم الثالث: المنتجات والأقسام (Products API) 🛍️ -> `ProductProvider`

*(هذه المسارات متاحة للزوار غير المسجلين)*

1. **جلب المنتجات**
   - **المسار:** `GET /products`
   - **الاستخدام:** يمكن تمرير Query Params مثل `category_id` للتصفية، أو `search` للبحث.
   - **سير العمل:** يقوم الـ `ProductProvider` بتخزين قائمة `List<Product>` وعرضها في `HomeScreen`.

2. **تفاصيل المنتج**
   - **المسار:** `GET /products/{id}`
   - **الوظيفة:** يجلب تفاصيل منتج معين مع معرض الصور الخاص به لإظهاره في `ProductDetailsScreen`.

---

### القسم الرابع: سلة المشتريات (Cart API) 🛒 -> `CartProvider`

*(تتطلب Bearer Token)*

1. **جلب السلة:** `GET /cart`
2. **إضافة منتج:** `POST /cart` (Body: `product_id`, `quantity` الافتراضي 1)
3. **تعديل الكمية:** `PUT /cart/{id}` (Body: `quantity`)
4. **حذف عنصر:** `DELETE /cart/{id}`

- **التوصيات للـ Provider:**
  - الـ `CartProvider` يجب أن يحتفظ بنسخة محلية للسلة ويحسب الإجمالي (`totalPrice`) بشكل ديناميكي لتوفير استجابة سريعة للـ UI، مع عمل **مزامنة (Sync)** بالخلفية للـ API عند كل تغيير.

---

### القسم الخامس: المفضلة (Favorites API) ❤️ -> `FavoriteProvider`

*(تتطلب Bearer Token)*

1. **جلب المفضلة:** `GET /favorites`
2. **إضافة للمفضلة:** `POST /favorites` (Body: `product_id`)
3. **حذف من المفضلة:** `DELETE /favorites/{product_id}`

- **التوصيات للـ Provider:** 
  - يجب تخزين قائمة بـ `product_id` للمفضلة محلياً، حتى تتمكن الـ `ProductCard` في واجهة قائمة المنتجات من رسم شكل قلب "ممتلئ" أو "فارغ" حسب وجود الـ ID.

---

### القسم السادس: الطلبات وعملية الدفع (Orders & Checkout) 📦 -> `OrderProvider`

*(تتطلب Bearer Token)*

يُعد هذا القسم المحور الأساسي للتطبيق نظراً لارتباطه برفع إيصال الدفع.

1. **حالة الطلبات السابقة:** 
   - `GET /orders` (قائمة الطلبات السابقة).
   - `GET /orders/{id}` (تفاصيل طلب محدد).

2. **تأكيد الطلب (Checkout):**
   - **المسار:** `POST /orders`
   - **النوعية (CRITICAL):** نظراً لوجود رفع صورة إيصال الدفع، **لا ترسل هذا الطلب كـ JSON بل استخدم `Multipart/form-data`**.
   - **الحقول النصية المطلوبة (Fields):**
     - `shipping_address` (string)
     - `shipping_phone` (string)
     - `notes` (اختياري)
   - **الملف المطلوب (File):**
     - `payment_receipt_image`: صورة إيصال التحويل (Sham Cash) التي اختارها/التقطها المستخدم من الهاتف (`max: 5MB`).
   - **سير العمل داخل التطبيق (Checkout Flow):**
     1. يعرض التطبيق شاشة Checkout تحتوي إجمالي السلة، فورم العنوان/الهاتف، وصورة صندوق الخادم (QR Code المجلوب من الإعدادات).
     2. يقوم المستخدم بالتحويل الخارجي، تصوير شاشة الدفع، ورفعها.
     3. يتم إرسال الطلب (MultipartRequest).
     4. عند نجاح الـ API (Status 201)، يجب **مسرياً تفريغ السلة المحلية** عبر `CartProvider.clearCart()` لأن الخادم يقوم بنقل محتويات الـ Cart إلى Order ويفضي السلة تلقائياً.

---

## 5. معالجة الأخطاء (Error Handling Policy)

لضمان دقة النظام وتجربة المستخدم الخالية من الأعطال الناجمة عن الشبكة/الأخطاء:

- **أخطاء المصادقة `401 Unauthorized`:** إذا أرجع أي استدعاء حالة 401، التقط الاستجابة فوراً بـ Interceptor، قم بعمل Logout وإجبار المستخدم على العودة لشاشة `LoginScreen`.
- **أخطاء التحقق `422 Unprocessable Entity`:** API لارافل ترجع الأخطاء بهذا الشكل:
  ```json
  {
    "message": "The given data was invalid.",
    "errors": {
      "email": ["The email has already been taken."],
      "payment_receipt_image": ["The file must be an image."]
    }
  }
  ```
  **تعليمات للـ Agent:** قم ببناء دالة لتحليل (`Parse`) كائن `errors` وعرضه للمستخدم بأناقة عبر رسائل `SnackBar` أو أسفل الـ `TextField` المخصص.

---

## 6. خارطة الطريق للـ AI Agent لبناء الـ Flutter App

عزيزي الـ **AI Agent**، لتحقيق هذا المشروع بكفاءة عبر Flutter + Provider، اتبع الخطوات التالية بالترتيب:

1. **Setup & Architecture:** قم بإنشاء هيكلية المجلدات (Models, Services, Providers, Screens, Widgets). قم بتكوين `Dio` أو `http` مع الـ Interceptors و Classes لمعالجة مسارات API.
2. **Auth Flow:** ابدأ ببرمجة الواجهات (`Login`, `Register`, `VerifyOTP`) واربطها بـ `AuthProvider` مع حفظ الـ Token بأمان محلياً.
3. **Products & Settings:** قم ببناء `ProductProvider` و `SettingsProvider`. صمم الـ `HomeScreen` لعرض المنتجات باستخدام Grid/List view، وجلب معلومات الكاش والتواصل في الخلفية.
4. **Cart & Favorites:** ابنِ `CartProvider` بحيث يتفاعل فوراً مع الـ UI ثم يزامن مع الخادم. أضِف تفاعلات "أضف للسلة" و "المفضلة" في كرت المنتج.
5. **Checkout & Orders:** برمجة تعقيد التطبيق الأكبر. ابنِ واجهة عربة التسوق. من ثم شاشة إتمام الدفع التي تقرأ `qr` من `SettingsProvider`، تطلب من المستخدم العنوان، ترفق صورة الإيصال بمكتبة مثل `image_picker`، ثم تستخدم طريقة **Multipart API Request** للإرسال.
6. **Polishing:** إضافة معالجات الأخطاء، وحالات التحميل (`Loaders/Shimmer`)، والـ Snackbars العائمة لردود فعل واضحة للمستخدم.

أنت الآن مسلح بكل تفاصيل عمل النظام الخلفي، تفضل بالبدء ببناء التطبيق 🚀!
