# توثيق شامل ومفصل للـ API الخاصة بمتجر Laravel 12 الإلكتروني

هذا التوثيق (بمثابة Swagger Documentation) يوضح بالتفاصيل الدقيقة كافة البيانات المطلوبة لكل نقطة نهاية (Endpoint)، مع أمثلة للطلبات والردود ورموز الحالة (Status Codes) ليكون المرجع الأساسي لمبرمج أو AI Agent الخاص بـ Flutter.

---

## روابط ومحددات أساسية (Base Configurations)

- **Base URL:** `http://127.0.0.1:8000/api` (أو مسار الخادم الفعلي).
- **Default Headers (لجميع الطلبات):**
  ```json
  {
    "Accept": "application/json",
    "Content-Type": "application/json"
  }
  ```
- **Authorization Header (للطلبات المحمية):**
  ```json
  {
    "Authorization": "Bearer {your_access_token}"
  }
  ```

---

## 1. قسم المصادقة (Authentication)

### 1.1 تسجيل حساب جديد (Register)
- **المسار:** `POST /register`
- **الحماية:** `Public`
- **الوصف:** إنشاء حساب مستخدم جديد.

**Request Body (JSON):**
```json
{
  "name": "Ahmed Ali",
  "email": "ahmed@example.com",
  "phone": "0912345678",
  "password": "SecurePassword123",
  "password_confirmation": "SecurePassword123"
}
```

**✅ Success Response (201 Created):**
```json
{
  "message": "User registered successfully. Please verify your email.",
  "user": {
    "id": 1,
    "name": "Ahmed Ali",
    "email": "ahmed@example.com",
    "phone": "0912345678",
    "role": "user"
  }
}
```

**❌ Error Response (422 Unprocessable Entity - Validation Failed):**
```json
{
  "message": "The given data was invalid.",
  "errors": {
    "email": ["The email has already been taken."],
    "password": ["The password confirmation does not match."]
  }
}
```

---

### 1.2 تأكيد الحساب (Verify Email)
- **المسار:** `POST /verify-email`
- **الحماية:** `Public`
- **الوصف:** تفعيل الحساب باستخدام رمز (OTP) تم إرساله مسبقاً عبر البريد الإلكتروني.

**Request Body (JSON):**
```json
{
  "email": "ahmed@example.com",
  "code": "123456"
}
```

**✅ Success Response (200 OK):**
```json
{
  "message": "Email verified successfully."
}
```

**❌ Error Response (422 Unprocessable Entity):**
```json
{
  "message": "The given data was invalid.",
  "errors": {
    "code": ["The verification code is invalid or has expired."]
  }
}
```

---

### 1.3 تسجيل الدخول (Login)
- **المسار:** `POST /login`
- **الحماية:** `Public`
- **الوصف:** المصادقة وإنشاء توكن (Token) للوصول للـ Endpoints المحمية.

**Request Body (JSON):**
```json
{
  "email": "ahmed@example.com",
  "password": "SecurePassword123"
}
```

**✅ Success Response (200 OK):**
```json
{
  "token": "1|abcdef1234567890abcdef1234567890",
  "user": {
    "id": 1,
    "name": "Ahmed Ali",
    "email": "ahmed@example.com",
    "phone": "0912345678",
    "role": "user"
  }
}
```

**❌ Error Response (401 Unauthorized - Wrong Credentials):**
```json
{
  "message": "Invalid credentials."
}
```

---

### 1.4 جلب بيانات المستخدم الحالي (Me)
- **المسار:** `GET /me`
- **الحماية:** `Bearer Token` مطلوب.
- **الوصف:** جلب معلومات المستخدم المسجل دخوله.

**✅ Success Response (200 OK):**
```json
{
  "data": {
    "id": 1,
    "name": "Ahmed Ali",
    "email": "ahmed@example.com",
    "phone": "0912345678",
    "role": "user"
  }
}
```

**❌ Error Response (401 Unauthorized):**
```json
{
  "message": "Unauthenticated."
}
```

---

### 1.5 تسجيل الخروج (Logout)
- **المسار:** `POST /logout`
- **الحماية:** `Bearer Token` مطلوب.
- **الوصف:** إبطال التوكن الحالي وتسجيل الخروج.

**✅ Success Response (200 OK):**
```json
{
  "message": "Logged out successfully."
}
```

---

## 2. الإعدادات العامة (Settings)

### 2.1 جلب الإعدادات (Get Settings)
- **المسار:** `GET /settings`
- **الحماية:** `Public`
- **الوصف:** جلب الإعدادات مثل كود QR التحويل وآلية التواصل.

**✅ Success Response (200 OK):**
```json
{
  "data": {
    "sham_cash_qr": "http://127.0.0.1:8000/storage/settings/qr_code.png",
    "admin_phone": "+963912345678"
  }
}
```

---

## 3. المنتجات والمفضلة (Products & Favorites)

### 3.1 جلب قائمة المنتجات (List Products)
- **المسار:** `GET /products`
- **الحماية:** `Public`
- **المعاملات (Query Params):** `?category_id=2` أو `?search=laptop`.

**✅ Success Response (200 OK - Paginated):**
```json
{
  "data": [
    {
      "id": 1,
      "category_id": 2,
      "name": "Gaming Laptop",
      "description": "High performance gaming laptop",
      "price": "1200.00",
      "stock": 10,
      "main_image": "http://127.0.0.1:8000/storage/products/laptop.jpg",
      "is_active": true
    }
  ],
  "meta": {
    "current_page": 1,
    "last_page": 5,
    "total": 50
  }
}
```

---

### 3.2 تفاصيل منتج محدد (Product Details)
- **المسار:** `GET /products/{id}`
- **الحماية:** `Public`
- **الوصف:** جلب تفاصيل منتج محدد شاملة صور المعرض (Gallery الصور المعروضة أسفل الصورة الرئيسية).

**✅ Success Response (200 OK):**
```json
{
  "data": {
    "id": 1,
    "name": "Gaming Laptop",
    "description": "High performance gaming laptop",
    "price": "1200.00",
    "main_image": "http://127.0.0.1:8000/storage/products/laptop.jpg",
    "images": [
      {
        "id": 1,
        "image_path": "http://127.0.0.1:8000/storage/products/gallery1.jpg"
      }
    ]
  }
}
```

**❌ Error (404 Not Found):**
```json
{
  "message": "No query results for model [App\\Models\\Product] 99"
}
```

---

### 3.3 جلب المنتجات المفضلة (List Favorites)
- **المسار:** `GET /favorites`
- **الحماية:** `Bearer Token` مطلوب.

**✅ Success Response (200 OK):**
```json
{
  "data": [
    {
      "product_id": 1,
      "name": "Gaming Laptop",
      "main_image": "http://127.0.0.1:8000/storage/products/laptop.jpg"
    }
  ]
}
```

---

### 3.4 إضافة/حذف من المفضلة (Toggle Favorite)
- **المسار:** `POST /favorites`
- **الحماية:** `Bearer Token` مطلوب.

**Request Body (JSON):**
```json
{
  "product_id": 1
}
```

**✅ Success Response (201 Created - Added):**
```json
{
  "message": "Product added to favorites."
}
```

و للحذف (استخدم DELETE): `DELETE /favorites/1` (حيث 1 هو `product_id`).

---

## 4. سلة المشتريات (Cart)

### 4.1 جلب محتويات السلة
- **المسار:** `GET /cart`
- **الحماية:** `Bearer Token` مطلوب.

**✅ Success Response (200 OK):**
```json
{
  "data": {
    "cart_id": 1,
    "total_price": 2400.00,
    "items": [
      {
        "cart_item_id": 5,
        "product": {
          "id": 1,
          "name": "Gaming Laptop",
          "price": "1200.00",
          "main_image": "http://127.0.0.1:8000/storage/products/laptop.jpg"
        },
        "quantity": 2
      }
    ]
  }
}
```

---

### 4.2 إضافة للسلة
- **المسار:** `POST /cart`
- **الحماية:** `Bearer Token` مطلوب.

**Request Body (JSON):**
```json
{
  "product_id": 1,
  "quantity": 1
}
```

**✅ Success Response (200 OK أو 201 Created):**
```json
{
  "message": "Product added to cart successfully."
}
```

---

### 4.3 تعديل أو حذف عنصر من السلة
- للحديل على الكمية استَخدِم: `PUT /cart/{cart_item_id}` 
  - Body: `{"quantity": 3}`
- للحذف استَخدم: `DELETE /cart/{cart_item_id}`.

---

## 5. الطلبات وعملية الدفع (Orders & Checkout)

### 5.1 إنشاء طلب (Checkout / Pay)
**هذه النقطة حساسة جداً (CRITICAL)**: نظراً للحاجة لرفع صورة إيصال الدفع، يجب استخدام `multipart/form-data` وليس JSON.

- **المسار:** `POST /orders`
- **الحماية:** `Bearer Token` مطلوب.
- **Headers المطلوبة:**
  ```json
  {
    "Authorization": "Bearer {your_access_token}",
    "Accept": "application/json",
    "Content-Type": "multipart/form-data" 
  }
  ```

**Request Body (FormData):**
- `shipping_address` (Text): "Damascus, Mazzeh, Street 1"
- `shipping_phone` (Text): "0912345678"
- `notes` (Text - Optional): "Please deliver after 5 PM."
- `payment_receipt_image` (File): *صورة مرفقة كملف بصيغة jpg/png وحجم لا يتجاوز 5MB.*

**✅ Success Response (201 Created):**
```json
{
  "message": "Order placed successfully. Awaiting payment verification.",
  "order": {
    "id": 15,
    "status": "unpaid",
    "total_amount": "2400.00",
    "payment_receipt_image": "http://127.0.0.1:8000/storage/receipts/img123.jpg"
  }
}
```

**❌ Error (422 Unprocessable Entity - Image/Cart Error):**
```json
{
  "message": "The given data was invalid.",
  "errors": {
    "payment_receipt_image": ["The payment receipt image must not be greater than 5000 kilobytes."],
    "cart": ["Your cart is empty. Cannot place an order."]
  }
}
```

---

### 5.2 جلب الطلبات السابقة
- **المسار:** `GET /orders`
- **الحماية:** `Bearer Token` مطلوب.

**✅ Success Response (200 OK):**
```json
{
  "data": [
    {
      "id": 15,
      "total_amount": "2400.00",
      "status": "unpaid",
      "created_at": "2026-03-16T10:00:00.000000Z"
    }
  ]
}
```

---

### 5.3 تفاصيل طلب محدد
- **المسار:** `GET /orders/{id}`
- **الحماية:** `Bearer Token` مطلوب.

**✅ Success Response (200 OK):**
```json
{
  "data": {
    "id": 15,
    "total_amount": "2400.00",
    "shipping_address": "Damascus, Mazzeh, Street 1",
    "status": "unpaid",
    "items": [
      {
        "id": 20,
        "product_name": "Gaming Laptop",
        "quantity": 2,
        "price": "1200.00"
      }
    ]
  }
}
```

---
**نهاية التوثيق API Documentation.**
