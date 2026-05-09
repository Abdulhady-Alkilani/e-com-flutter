# تقرير AI Agent — دليل تنفيذ Flutter للتعامل مع التعديلات الجديدة

## مقدمة
هذا التقرير موجّه لـ AI Agent المسؤول عن تطوير تطبيق Flutter. يحتوي على جميع التفاصيل التقنية اللازمة لتنفيذ التعديلات على التطبيق بما يتوافق مع التغييرات الجديدة في الـ API.

---

## 1. تغييرات الـ API — ملخص

### Base URL
```
http://{SERVER_IP}:8000/api
```

### الـ Endpoints العامة (بدون تسجيل دخول — وضع الزائر):
| Method | Endpoint | الوصف |
|--------|----------|-------|
| `POST` | `/api/register` | إنشاء حساب جديد (بدون OTP) |
| `POST` | `/api/login` | تسجيل الدخول |
| `GET` | `/api/categories` | قائمة الفئات النشطة |
| `GET` | `/api/products` | قائمة المنتجات مع فلترة وفرز |
| `GET` | `/api/products/{id}` | تفاصيل منتج واحد |
| `GET` | `/api/settings` | إعدادات النظام |

### الـ Endpoints المحمية (تتطلب تسجيل دخول):
| Method | Endpoint | الوصف |
|--------|----------|-------|
| `GET` | `/api/me` | بيانات المستخدم الحالي |
| `POST` | `/api/profile/update` | تحديث الملف الشخصي |
| `POST` | `/api/logout` | تسجيل الخروج |
| `GET` | `/api/cart` | عرض السلة |
| `POST` | `/api/cart` | إضافة منتج للسلة |
| `PUT` | `/api/cart/{id}` | تحديث كمية عنصر في السلة |
| `DELETE` | `/api/cart/{id}` | حذف عنصر من السلة |
| `GET` | `/api/orders` | قائمة الطلبات |
| `POST` | `/api/orders` | إنشاء طلب جديد |
| `GET` | `/api/orders/{id}` | تفاصيل طلب |
| `GET` | `/api/favorites` | قائمة المفضلة |
| `POST` | `/api/favorites` | إضافة للمفضلة |
| `DELETE` | `/api/favorites/{productId}` | حذف من المفضلة |

---

## 2. المصادقة (Authentication) — بدون OTP

### ⚠️ تغيير مهم: تم إلغاء نظام OTP بالكامل
التسجيل أصبح مباشر — المستخدم ينشئ حساب ويحصل على Token فوراً بدون أي تحقق من البريد.

### `POST /api/register` — إنشاء حساب

**الطلب:**
```json
{
  "name": "أحمد علي",
  "email": "ahmad@example.com",
  "phone": "+963912345678",
  "password": "password123",
  "password_confirmation": "password123"
}
```

**استجابة نجاح (201):**
```json
{
  "message": "تم إنشاء الحساب بنجاح.",
  "user": {
    "id": 1,
    "name": "أحمد علي",
    "email": "ahmad@example.com",
    "phone": "+963912345678",
    "role": "user"
  },
  "token": "1|abc123def456..."
}
```

**استجابة خطأ — بريد مكرر (422):**
```json
{
  "message": "The given data was invalid.",
  "errors": {
    "email": ["The email has already been taken."]
  }
}
```

### `POST /api/login` — تسجيل الدخول

**الطلب:**
```json
{
  "email": "ahmad@example.com",
  "password": "password123"
}
```

**استجابة نجاح (200):**
```json
{
  "user": {
    "id": 1,
    "name": "أحمد علي",
    "email": "ahmad@example.com",
    "role": "user"
  },
  "token": "2|xyz789..."
}
```

**استجابة خطأ (422):**
```json
{
  "message": "The given data was invalid.",
  "errors": {
    "email": ["البريد الإلكتروني أو كلمة المرور غير صحيحة."]
  }
}
```

### `POST /api/logout` — تسجيل الخروج (يتطلب Token)

**Header:** `Authorization: Bearer {token}`

**استجابة نجاح (200):**
```json
{
  "message": "تم تسجيل الخروج بنجاح."
}
```

### `GET /api/me` — بيانات المستخدم الحالي (يتطلب Token)

**استجابة:**
```json
{
  "data": {
    "id": 1,
    "name": "أحمد علي",
    "email": "ahmad@example.com",
    "phone": "+963912345678",
    "role": "user",
    "avatar": "http://localhost/storage/avatars/photo.jpg"
  }
}
```

### `POST /api/profile/update` — تحديث الملف الشخصي (يتطلب Token)

**الطلب (FormData — لدعم رفع الصورة):**
```
name: أحمد محمد
email: new@example.com
phone: +963999888777
password: newPassword123          (اختياري)
password_confirmation: newPassword123  (مطلوب إذا كان password موجود)
avatar: [file]                    (اختياري — صورة jpeg/png/jpg/gif, حد 2MB)
```

**استجابة نجاح (200):**
```json
{
  "message": "تم تحديث الملف الشخصي بنجاح.",
  "data": {
    "id": 1,
    "name": "أحمد محمد",
    "email": "new@example.com",
    "phone": "+963999888777",
    "role": "user",
    "avatar": "http://localhost/storage/avatars/newphoto.jpg"
  }
}
```

### التنفيذ في Flutter — AuthService:

```dart
class AuthService {
  final Dio _dio;

  AuthService(this._dio);

  /// إنشاء حساب جديد — يُرجع Token فوراً بدون OTP
  Future<AuthResult> register({
    required String name,
    required String email,
    required String phone,
    required String password,
    required String passwordConfirmation,
  }) async {
    try {
      final response = await _dio.post('/register', data: {
        'name': name,
        'email': email,
        'phone': phone,
        'password': password,
        'password_confirmation': passwordConfirmation,
      });

      final user = User.fromJson(response.data['user']);
      final token = response.data['token'] as String;

      return AuthResult(user: user, token: token);
    } on DioException catch (e) {
      throw ApiException.fromDioError(e);
    }
  }

  /// تسجيل الدخول
  Future<AuthResult> login({
    required String email,
    required String password,
  }) async {
    try {
      final response = await _dio.post('/login', data: {
        'email': email,
        'password': password,
      });

      final user = User.fromJson(response.data['user']);
      final token = response.data['token'] as String;

      return AuthResult(user: user, token: token);
    } on DioException catch (e) {
      throw ApiException.fromDioError(e);
    }
  }

  /// تسجيل الخروج
  Future<void> logout() async {
    await _dio.post('/logout');
  }

  /// جلب بيانات المستخدم
  Future<User> getProfile() async {
    final response = await _dio.get('/me');
    return User.fromJson(response.data['data']);
  }
}

class AuthResult {
  final User user;
  final String token;
  AuthResult({required this.user, required this.token});
}
```

### AuthProvider (State Management):

```dart
class AuthProvider extends ChangeNotifier {
  String? _token;
  User? _user;

  bool get isGuest => _token == null;
  bool get isAuthenticated => _token != null;
  User? get user => _user;
  String? get token => _token;

  /// بعد التسجيل أو تسجيل الدخول — حفظ Token محلياً
  Future<void> authenticate(AuthResult result) async {
    _token = result.token;
    _user = result.user;
    // حفظ في SharedPreferences
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('token', result.token);
    notifyListeners();
  }

  Future<void> logout() async {
    _token = null;
    _user = null;
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('token');
    notifyListeners();
  }

  /// محاولة تحميل Token المحفوظ عند بدء التطبيق
  Future<void> tryAutoLogin() async {
    final prefs = await SharedPreferences.getInstance();
    final savedToken = prefs.getString('token');
    if (savedToken != null) {
      _token = savedToken;
      // اختيارياً: جلب بيانات المستخدم
      notifyListeners();
    }
  }
}
```

### User Model:

```dart
class User {
  final int id;
  final String name;
  final String email;
  final String? phone;
  final String role;
  final String? avatar;

  User({
    required this.id,
    required this.name,
    required this.email,
    this.phone,
    required this.role,
    this.avatar,
  });

  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      id: json['id'],
      name: json['name'],
      email: json['email'],
      phone: json['phone'],
      role: json['role'] ?? 'user',
      avatar: json['avatar'],
    );
  }
}
```

---

## 3. وضع الزائر (Guest Mode) — التنفيذ في Flutter

### المطلوب:
يجب أن يتمكن المستخدم غير المسجل من:
1. **تصفح المنتجات** — عرض قائمة المنتجات مع الصور والأسعار
2. **عرض تفاصيل المنتج** — الضغط على منتج لعرض تفاصيله الكاملة (الصور، الوصف، المقاسات، السعر)
3. **البحث** — البحث في المنتجات بالاسم أو الوصف
4. **الفرز** — ترتيب المنتجات حسب السعر أو الاسم أو التاريخ
5. **الفلترة** — فلترة حسب الفئة، نطاق السعر، التوفر

### التصميم المقترح:

#### شاشة رئيسية (HomeScreen)
```
┌─────────────────────────┐
│  شريط البحث 🔍          │
├─────────────────────────┤
│  فئات (أفقي) ←→         │
│  [ألبسة] [إلكترونيات]    │
├─────────────────────────┤
│  أيقونة فرز ↕ + فلترة 🔧│
├─────────────────────────┤
│  ┌──────┐ ┌──────┐      │
│  │ صورة │ │ صورة │      │
│  │ اسم  │ │ اسم  │      │
│  │ سعر  │ │ سعر  │      │
│  │ متوفر│ │ نفذ  │      │
│  └──────┘ └──────┘      │
│  ┌──────┐ ┌──────┐      │
│  │ ...  │ │ ...  │      │
│  └──────┘ └──────┘      │
├─────────────────────────┤
│ [تسجيل الدخول للمزيد]   │
└─────────────────────────┘
```

#### عند محاولة إضافة للسلة/المفضلة بدون تسجيل:
- عرض `BottomSheet` أو `Dialog` يدعو المستخدم لتسجيل الدخول
- زر "تسجيل الدخول" → يوجه لصفحة Login
- زر "متابعة التصفح" → يغلق الـ dialog

### كيفية تحديد وضع الزائر:
```dart
class AuthProvider extends ChangeNotifier {
  String? _token;
  bool get isGuest => _token == null;
  bool get isAuthenticated => _token != null;
}
```

---

## 4. نظام المقاسات — التنفيذ في Flutter

### التغيير في API Response:
**قبل:**
```json
{
  "id": 1,
  "name": "قميص رجالي",
  "external_link": "https://youtube.com/..."
}
```

**بعد:**
```json
{
  "id": 1,
  "name": "قميص رجالي",
  "sizes": [
    {"size": "S", "quantity": 5},
    {"size": "M", "quantity": 10},
    {"size": "L", "quantity": 3},
    {"size": "كبير", "quantity": 7},
    {"size": "وسط", "quantity": 12}
  ],
  "in_stock": true,
  "stock": 37
}
```

### Model في Flutter:

```dart
class ProductSize {
  final String size;
  final int quantity;

  ProductSize({required this.size, required this.quantity});

  factory ProductSize.fromJson(Map<String, dynamic> json) {
    return ProductSize(
      size: json['size'] as String,
      quantity: json['quantity'] as int,
    );
  }

  bool get isAvailable => quantity > 0;
}

class Product {
  final int id;
  final String name;
  final String description;
  final double price;
  final int stock;
  final bool inStock;
  final List<ProductSize>? sizes;
  final String? mainImage;
  final bool isActive;
  final Category category;
  final List<ProductImage> images;
  final DateTime createdAt;
  final DateTime updatedAt;

  Product({
    required this.id,
    required this.name,
    required this.description,
    required this.price,
    required this.stock,
    required this.inStock,
    this.sizes,
    this.mainImage,
    required this.isActive,
    required this.category,
    required this.images,
    required this.createdAt,
    required this.updatedAt,
  });

  factory Product.fromJson(Map<String, dynamic> json) {
    return Product(
      id: json['id'],
      name: json['name'],
      description: json['description'],
      price: (json['price'] as num).toDouble(),
      stock: json['stock'],
      inStock: json['in_stock'] ?? false,
      sizes: json['sizes'] != null
          ? (json['sizes'] as List).map((s) => ProductSize.fromJson(s)).toList()
          : null,
      mainImage: json['main_image'],
      isActive: json['is_active'],
      category: Category.fromJson(json['category']),
      images: (json['images'] as List).map((i) => ProductImage.fromJson(i)).toList(),
      createdAt: DateTime.parse(json['created_at']),
      updatedAt: DateTime.parse(json['updated_at']),
    );
  }

  /// هل المنتج يحتوي على مقاسات
  bool get hasSizes => sizes != null && sizes!.isNotEmpty;

  /// المقاسات المتوفرة فقط
  List<ProductSize> get availableSizes =>
      sizes?.where((s) => s.isAvailable).toList() ?? [];
}
```

### واجهة اختيار المقاس في صفحة تفاصيل المنتج:

```dart
class SizeSelectorWidget extends StatefulWidget {
  final List<ProductSize> sizes;
  final Function(ProductSize) onSizeSelected;

  const SizeSelectorWidget({
    required this.sizes,
    required this.onSizeSelected,
  });

  @override
  State<SizeSelectorWidget> createState() => _SizeSelectorWidgetState();
}

class _SizeSelectorWidgetState extends State<SizeSelectorWidget> {
  ProductSize? selectedSize;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'اختر المقاس:',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: widget.sizes.map((size) {
            final isSelected = selectedSize == size;
            final isAvailable = size.isAvailable;

            return GestureDetector(
              onTap: isAvailable
                  ? () {
                      setState(() => selectedSize = size);
                      widget.onSizeSelected(size);
                    }
                  : null,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                decoration: BoxDecoration(
                  color: isSelected
                      ? Theme.of(context).primaryColor
                      : isAvailable
                          ? Colors.white
                          : Colors.grey[300],
                  border: Border.all(
                    color: isSelected
                        ? Theme.of(context).primaryColor
                        : Colors.grey[400]!,
                    width: isSelected ? 2 : 1,
                  ),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Column(
                  children: [
                    Text(
                      size.size,
                      style: TextStyle(
                        color: isSelected
                            ? Colors.white
                            : isAvailable
                                ? Colors.black
                                : Colors.grey,
                        fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                        decoration: isAvailable ? null : TextDecoration.lineThrough,
                      ),
                    ),
                    if (isAvailable)
                      Text(
                        'متوفر: ${size.quantity}',
                        style: TextStyle(
                          fontSize: 10,
                          color: isSelected ? Colors.white70 : Colors.grey,
                        ),
                      ),
                  ],
                ),
              ),
            );
          }).toList(),
        ),
      ],
    );
  }
}
```

---

## 5. التحقق من الكمية — التنفيذ في Flutter

### سيناريوهات الأخطاء الجديدة:

#### عند إضافة للسلة (`POST /api/cart`):

**طلب عادي:**
```json
{
  "product_id": 1,
  "quantity": 2
}
```

**استجابة نجاح (200):**
```json
{
  "message": "تمت إضافة المنتج إلى السلة بنجاح.",
  "data": {
    "id": 1,
    "quantity": 2,
    "product": { ... }
  }
}
```

**استجابة خطأ — منتج غير نشط (400):**
```json
{
  "message": "المنتج غير متاح حالياً."
}
```

**استجابة خطأ — كمية غير متوفرة (422):**
```json
{
  "message": "الكمية المطلوبة غير متوفرة. الكمية المتاحة: 3"
}
```

#### عند تحديث كمية السلة (`PUT /api/cart/{id}`):

**استجابة خطأ — كمية غير متوفرة (422):**
```json
{
  "message": "الكمية المطلوبة غير متوفرة. الكمية المتاحة: 3"
}
```

#### عند إنشاء طلب (`POST /api/orders`):

**استجابة خطأ — سلة فارغة (400):**
```json
{
  "message": "السلة فارغة."
}
```

**استجابة خطأ — كمية غير متوفرة (422):**
```json
{
  "message": "الكمية المطلوبة غير متوفرة لبعض المنتجات.",
  "errors": [
    "المنتج \"قميص رجالي\": الكمية المطلوبة (4) غير متوفرة. المتاح: 3",
    "المنتج \"حذاء رياضي\" غير متاح حالياً."
  ]
}
```

### التعامل مع الأخطاء في Flutter:

```dart
class CartService {
  final Dio _dio;

  CartService(this._dio);

  Future<Result<CartItem>> addToCart(int productId, int quantity) async {
    try {
      final response = await _dio.post('/cart', data: {
        'product_id': productId,
        'quantity': quantity,
      });
      return Result.success(CartItem.fromJson(response.data['data']));
    } on DioException catch (e) {
      final statusCode = e.response?.statusCode;
      final message = e.response?.data['message'] ?? 'حدث خطأ غير متوقع';

      if (statusCode == 422) {
        // الكمية غير متوفرة — عرض رسالة مع الكمية المتاحة
        // يمكن استخراج الرقم من الرسالة
        return Result.error(StockError(message));
      } else if (statusCode == 400) {
        // المنتج غير متاح
        return Result.error(ProductUnavailableError(message));
      }
      return Result.error(GeneralError(message));
    }
  }

  Future<Result<CartItem>> updateCartItem(int cartItemId, int quantity) async {
    try {
      final response = await _dio.put('/cart/$cartItemId', data: {
        'quantity': quantity,
      });
      return Result.success(CartItem.fromJson(response.data['data']));
    } on DioException catch (e) {
      final message = e.response?.data['message'] ?? 'حدث خطأ غير متوقع';
      if (e.response?.statusCode == 422) {
        return Result.error(StockError(message));
      }
      return Result.error(GeneralError(message));
    }
  }
}
```

### عرض رسائل الخطأ في الواجهة:

```dart
void _handleAddToCart() async {
  final result = await cartService.addToCart(product.id, selectedQuantity);

  result.when(
    success: (cartItem) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('تمت إضافة المنتج إلى السلة بنجاح'),
          backgroundColor: Colors.green,
        ),
      );
    },
    error: (error) {
      if (error is StockError) {
        // عرض Dialog مع الكمية المتاحة
        showDialog(
          context: context,
          builder: (ctx) => AlertDialog(
            title: const Text('الكمية غير متوفرة'),
            content: Text(error.message),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx),
                child: const Text('حسناً'),
              ),
            ],
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(error.message),
            backgroundColor: Colors.red,
          ),
        );
      }
    },
  );
}
```

---

## 6. البحث والفرز والفلترة — التنفيذ في Flutter

### بناء URL مع المعاملات:

```dart
class ProductService {
  final Dio _dio;

  ProductService(this._dio);

  Future<PaginatedResponse<Product>> getProducts({
    int? categoryId,
    String? search,
    double? minPrice,
    double? maxPrice,
    bool? inStock,
    String? sortBy,     // 'price', 'name', 'created_at'
    String? sortOrder,  // 'asc', 'desc'
    int page = 1,
  }) async {
    final queryParams = <String, dynamic>{
      'page': page,
    };

    if (categoryId != null) queryParams['category_id'] = categoryId;
    if (search != null && search.isNotEmpty) queryParams['search'] = search;
    if (minPrice != null) queryParams['min_price'] = minPrice;
    if (maxPrice != null) queryParams['max_price'] = maxPrice;
    if (inStock == true) queryParams['in_stock'] = 'true';
    if (sortBy != null) queryParams['sort_by'] = sortBy;
    if (sortOrder != null) queryParams['sort_order'] = sortOrder;

    final response = await _dio.get('/products', queryParameters: queryParams);

    final products = (response.data['data'] as List)
        .map((json) => Product.fromJson(json))
        .toList();

    final pagination = response.data['pagination'];

    return PaginatedResponse(
      data: products,
      total: pagination['total'],
      perPage: pagination['per_page'],
      currentPage: pagination['current_page'],
      lastPage: pagination['last_page'],
    );
  }
}
```

### أمثلة على استخدام الفلترة:
```dart
// البحث عن "قميص"
await productService.getProducts(search: 'قميص');

// فلترة حسب الفئة + الأرخص أولاً
await productService.getProducts(
  categoryId: 1,
  sortBy: 'price',
  sortOrder: 'asc',
);

// منتجات متوفرة فقط بسعر بين 5000 و 20000
await productService.getProducts(
  minPrice: 5000,
  maxPrice: 20000,
  inStock: true,
);
```

### واجهة الفلترة (FilterSheet):

```dart
class FilterBottomSheet extends StatefulWidget {
  final Function(FilterOptions) onApply;

  const FilterBottomSheet({required this.onApply});

  @override
  State<FilterBottomSheet> createState() => _FilterBottomSheetState();
}

class _FilterBottomSheetState extends State<FilterBottomSheet> {
  RangeValues _priceRange = const RangeValues(0, 100000);
  bool _inStockOnly = false;
  String _sortBy = 'created_at';
  String _sortOrder = 'desc';
  int? _selectedCategoryId;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // العنوان
          const Text('فلترة المنتجات', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
          const SizedBox(height: 16),

          // نطاق السعر
          const Text('نطاق السعر (ل.س)'),
          RangeSlider(
            values: _priceRange,
            min: 0,
            max: 100000,
            divisions: 100,
            labels: RangeLabels(
              '${_priceRange.start.toInt()}',
              '${_priceRange.end.toInt()}',
            ),
            onChanged: (values) => setState(() => _priceRange = values),
          ),

          // متوفر فقط
          SwitchListTile(
            title: const Text('المنتجات المتوفرة فقط'),
            value: _inStockOnly,
            onChanged: (value) => setState(() => _inStockOnly = value),
          ),

          // الترتيب
          const Text('ترتيب حسب'),
          DropdownButton<String>(
            value: _sortBy,
            isExpanded: true,
            items: const [
              DropdownMenuItem(value: 'created_at', child: Text('الأحدث')),
              DropdownMenuItem(value: 'price', child: Text('السعر')),
              DropdownMenuItem(value: 'name', child: Text('الاسم')),
            ],
            onChanged: (value) => setState(() => _sortBy = value!),
          ),

          // اتجاه الترتيب
          DropdownButton<String>(
            value: _sortOrder,
            isExpanded: true,
            items: const [
              DropdownMenuItem(value: 'asc', child: Text('تصاعدي ↑')),
              DropdownMenuItem(value: 'desc', child: Text('تنازلي ↓')),
            ],
            onChanged: (value) => setState(() => _sortOrder = value!),
          ),

          const SizedBox(height: 16),

          // زر التطبيق
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () {
                widget.onApply(FilterOptions(
                  minPrice: _priceRange.start,
                  maxPrice: _priceRange.end,
                  inStock: _inStockOnly,
                  sortBy: _sortBy,
                  sortOrder: _sortOrder,
                  categoryId: _selectedCategoryId,
                ));
                Navigator.pop(context);
              },
              child: const Text('تطبيق الفلترة'),
            ),
          ),
        ],
      ),
    );
  }
}
```

---

## 7. تحديث CategoryController — عدد المنتجات

### Response الجديد:
```json
{
  "data": [
    {
      "id": 1,
      "name": "ألبسة",
      "image": "http://localhost/storage/categories/clothing.png",
      "is_active": true,
      "products_count": 15
    },
    {
      "id": 2,
      "name": "إلكترونيات",
      "image": "http://localhost/storage/categories/electronics.png",
      "is_active": true,
      "products_count": 8
    }
  ]
}
```

### Model في Flutter:
```dart
class Category {
  final int id;
  final String name;
  final String? image;
  final bool isActive;
  final int productsCount;  // جديد

  Category({
    required this.id,
    required this.name,
    this.image,
    required this.isActive,
    this.productsCount = 0,
  });

  factory Category.fromJson(Map<String, dynamic> json) {
    return Category(
      id: json['id'],
      name: json['name'],
      image: json['image'],
      isActive: json['is_active'] ?? true,
      productsCount: json['products_count'] ?? 0,  // جديد
    );
  }
}
```

---

## 8. قائمة المهام للتنفيذ في Flutter

### مطلوب:

#### المصادقة (بدون OTP)
- [ ] إنشاء `User` model
- [ ] إنشاء `AuthService` — register + login + logout + getProfile + updateProfile
- [ ] إنشاء `AuthProvider` — إدارة حالة المصادقة وحفظ Token في SharedPreferences
- [ ] إنشاء شاشة تسجيل الدخول `LoginScreen` — بريد + كلمة مرور
- [ ] إنشاء شاشة إنشاء حساب `RegisterScreen` — اسم + بريد + هاتف + كلمة مرور + تأكيد
- [ ] إنشاء شاشة تعديل الملف الشخصي `ProfileScreen` — تحديث البيانات + رفع صورة
- [ ] ⚠️ **لا يوجد OTP** — بعد التسجيل يحصل المستخدم على Token مباشرة
- [ ] ⚠️ **لا يوجد شاشة verify-email** — تم إلغاؤها بالكامل

#### المنتجات والمقاسات
- [ ] تحديث `Product` model — إزالة `externalLink` وإضافة `sizes` و `inStock`
- [ ] إنشاء `ProductSize` model
- [ ] تحديث `Category` model — إضافة `productsCount`
- [ ] إنشاء `SizeSelectorWidget` لاختيار المقاس
- [ ] تحديث `ProductService` — إضافة معاملات الفلترة والفرز
- [ ] تحديث `CartService` — التعامل مع أخطاء الكمية (422, 400)
- [ ] إنشاء `FilterBottomSheet` للفلترة المتقدمة
- [ ] تحديث صفحة تفاصيل المنتج — عرض المقاسات + التحقق من التوفر
- [ ] تحديث صفحة السلة — عرض رسائل الخطأ عند تجاوز الكمية
- [ ] تنفيذ وضع الزائر — تصفح بدون تسجيل + Dialog للتسجيل عند الحاجة
- [ ] تحديث شاشة الفئات — عرض عدد المنتجات لكل فئة
- [ ] إضافة شريط بحث في الصفحة الرئيسية
- [ ] إضافة خيارات الفرز (السعر/الاسم/الأحدث)

### ملاحظات مهمة:
1. **لا يوجد OTP** — التسجيل مباشر، الـ API يُرجع `token` فوراً مع `register`
2. **المقاسات اختيارية** — بعض المنتجات قد لا تحتوي على مقاسات (`sizes: null`)
3. **رسائل الخطأ بالعربية** — يجب عرضها كما هي من الـ API
4. **الحقل `in_stock`** — يمكن استخدامه لعرض شارة "متوفر/نفذ" على بطاقة المنتج
5. **الحقل `stock`** — العدد الكلي للمخزون (مجموع كميات المقاسات)
6. **وضع الزائر** لا يتطلب أي token — الـ endpoints العامة لا ترسل `Authorization` header
7. **تحديث الملف الشخصي** يستخدم `FormData` (ليس JSON) لأنه يدعم رفع صور
