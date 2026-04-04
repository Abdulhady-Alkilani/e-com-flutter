# Flutter Agent Guide — API Updates & Filter Section Maintenance

**For:** Flutter AI Agent / Flutter Developer  
**Date:** 2026-04-02  
**Backend:** Laravel (e-com-api-laravel)  
**Priority:** ACTION REQUIRED for filter section

---

## 🎯 Overview

The backend has been updated based on `fic.md`. This document tells you exactly what changed and what you need to verify/update in Flutter.

---

## ✅ Issue #1 — `/categories` Endpoint is NOW LIVE

### Status: Backend fixed. No Flutter changes needed.

The endpoint `GET /api/categories` is now implemented and **public** (no token required).

**Endpoint:**
```
GET /api/categories
Accept: application/json
```
*(No Authorization header needed)*

**Response:**
```json
{
  "data": [
    {
      "id": 1,
      "name": "Clothing (ألبسة)",
      "image": "http://server/storage/categories/clothing-cat.png",
      "is_active": true
    }
  ]
}
```

**Flutter `ProductProvider.fetchCategories()` should parse:**
```dart
final List data = response.data['data'];
// Map to CategoryModel list
```

> ✅ No code change needed IF Flutter already reads from `response.data['data']`.

---

## ✅ Issue #2 — Cart Route Confirmed: `POST /api/cart`

### Status: Confirmed. No Flutter changes needed.

The backend uses `POST /api/cart` (NOT `/api/cart/add`).

**Current Flutter constant is CORRECT:**
```dart
// lib/core/constants/api_constants.dart
static const String cart = '/cart';  // ✅ keep this
```

All cart operations:
| Action | Method | Endpoint |
|--------|--------|----------|
| Get cart | `GET` | `/api/cart` |
| Add item | `POST` | `/api/cart` |
| Update qty | `PUT` | `/api/cart/{cart_item_id}` |
| Remove item | `DELETE` | `/api/cart/{cart_item_id}` |

---

## ✅ Issue #3 — `/me` Response NOW Wrapped in `data`

### Status: Backend fixed. Verify Flutter handles it.

The `/me` endpoint now returns:
```json
{
  "data": {
    "id": 1,
    "name": "Ahmad Ali",
    "email": "user@example.com",
    "phone": "+963912345678",
    "role": "user",
    "avatar": "http://server/storage/avatars/photo.jpg"
  }
}
```

**Verify Flutter `AuthProvider` or `UserModel.fromJson` uses:**
```dart
final data = response.data['data'] ?? response.data;  // ✅ safe fallback
```

**If adding avatar support, update `UserModel`:**
```dart
class UserModel {
  // Add this field:
  final String? avatar;

  UserModel.fromJson(Map<String, dynamic> json)
      : avatar = json['avatar'] as String?,
        // ... rest of fields
}
```

---

## ✅ Issue #5 — Settings Key: `admin_phone` is Confirmed

### Status: Backend fixed. Flutter update REQUIRED.

The settings endpoint now returns `admin_phone` (the correct key).

**Endpoint:**
```
GET /api/settings
```

**Response:**
```json
{
  "data": {
    "admin_phone": "+963999999999",
    "sham_cash_qr": "http://server/storage/qr_codes/shamcash_demo.png"
  }
}
```

> ⚠️ **IMPORTANT:** The response is NOW wrapped in `"data"` key!

**Update your `SettingsProvider` to read:**
```dart
// OLD (broken — does not work anymore):
_adminPhone = response.data['admin_phone'] as String?;
_qrCode = response.data['sham_cash_qr'] as String?;

// NEW (correct):
final data = response.data['data'];
_adminPhone = data['admin_phone'] as String?;
_qrCode = data['sham_cash_qr'] as String?;
```

---

## ✅ Issue #6 — Avatar Field Now in `/me`

### Status: Backend fixed. Flutter update recommended.

The `avatar` field is now included in `/me` response as a full URL.  
Update `UserModel` to parse it (see Issue #3 section above).

---

## 🔧 Filter Section — Category Filter

The category filter in the products screen relies on `GET /api/categories`.  
Now that the endpoint exists, verify:

1. **`ProductProvider.fetchCategories()`** calls `GET /api/categories`
2. Parses `response.data['data']` as a list
3. Filter chip passes `category_id` as query param:
   ```
   GET /api/products?category_id=2
   ```

**Products endpoint supports:**
```
GET /api/products
GET /api/products?category_id={id}
GET /api/products?search={term}
GET /api/products?category_id={id}&search={term}
```

---

## 🚨 Error Handling Recommendations

Add these to Flutter HTTP error handling:

| Status | Scenario | Flutter Action |
|--------|----------|----------------|
| `422` with `errors.stock` | Out-of-stock add to cart | Show "Product out of stock" snackbar |
| `200` on duplicate favorite | Adding already-favorited product | Handle gracefully (already in favorites) |
| `422` with `errors.cart` | Checkout with empty cart | Show "Cart is empty" message |

---

## 📁 Files Affected on Backend (Reference)

```
routes/api.php                           ← new GET /categories route
app/Http/Controllers/Api/
  ├── CategoryController.php             ← [NEW]
  ├── AuthController.php                 ← /me now returns {data: {..., avatar}}
  └── SettingsController.php             ← {data: {admin_phone, sham_cash_qr}}
app/Models/SystemSetting.php             ← single-record model
database/migrations/
  └── 2026_04_02_000001_refactor...php   ← [NEW] schema change
```

---

## ⚡ Quick Verification Checklist

After backend migration runs (`php artisan migrate`), test these:

- [ ] `GET /api/categories` returns 200 with `data` array (no token)
- [ ] `GET /api/products?category_id=1` filters correctly
- [ ] `GET /api/settings` returns `data.admin_phone` and `data.sham_cash_qr`
- [ ] `GET /api/me` (with token) returns `data.avatar` (nullable)
- [ ] `POST /api/cart` adds item (not `/api/cart/add`)
- [ ] Duplicate favorite returns 200 (not 422)

---

*End of Flutter Agent Guide — 2026-04-02*
