# fic.md — Backend & API Fixes Required
## Addressed to: Backend AI Agent / Laravel Developer

**Date:** 2026-03-31  
**Priority:** HIGH  
**Context:** Flutter client is implemented. These API discrepancies were discovered during Flutter-backend integration analysis.

---

## Summary

During analysis of the Flutter app against `apiReport1.md`, `Report1.md`, and `Flutter.md`, the following backend/API inconsistencies were identified. The Flutter client has been coded to match `apiReport1.md`, but some endpoints in `apiReport1.md` conflict with `userReport.md`.

---

## Issue #1 — Missing `GET /categories` Endpoint in API Docs

**Severity:** HIGH — App will fail to load category filters

**Problem:**  
The Flutter `ProductProvider.fetchCategories()` calls `GET /api/categories`, but this endpoint is **NOT documented** in `apiReport1.md`. It only appears implicitly in `userReport.md` (Section 4.2).

**Flutter code expecting:**
```http
GET /api/categories
Authorization: Bearer {token}
Accept: application/json
```

**Expected Response:**
```json
{
  "data": [
    {
      "id": 1,
      "name": "الإلكترونيات",
      "image": "http://server/storage/categories/img.jpg",
      "is_active": true
    }
  ]
}
```

**Action Required for Backend:**
- Confirm the endpoint exists at `GET /api/categories`
- Ensure it is public (no auth required) consistent with products being public
- Add to API documentation

---

## Issue #2 — Cart Endpoint Path Conflict

**Severity:** MEDIUM — Potential 404 on add-to-cart

**Problem:**  
`userReport.md` (Section 4.3) documents `POST /api/cart/add` but `apiReport1.md` (Section 4.2) documents `POST /api/cart`.

The Flutter implementation uses `POST /api/cart` (from `apiReport1.md`).

| Source | Endpoint |
|--------|----------|
| `apiReport1.md` | `POST /api/cart` (with body: `product_id`, `quantity`) |
| `userReport.md` | `POST /api/cart/add` |

**Action Required for Backend:**
- Confirm which is the actual route: `/api/cart` or `/api/cart/add`
- If `/api/cart/add` — update Flutter `api_constants.dart`:
  ```dart
  // lib/core/constants/api_constants.dart
  static const String cartAdd = '/cart/add';  // change this
  ```
- If `/api/cart` — update `userReport.md` to reflect the correct path

---

## Issue #3 — `GET /me` Response Format Inconsistency

**Severity:** LOW — Handled gracefully in Flutter, but should be standardized

**Problem:**  
`apiReport1.md` shows:
```json
{
  "data": {
    "id": 1, "name": "...", "email": "...", ...
  }
}
```

Flutter handles this with a fallback:
```dart
final data = response.data['data'] ?? response.data;
```

**Recommendation:** Standardize all authenticated user responses to always wrap in `"data"` key for consistency.

---

## Issue #4 — Cart Update Endpoint Typo in `userReport.md`

**Severity:** LOW — informational

**In `userReport.md` Section 4.3:**  
`updateQuantity(int cartItemId, int quantity)`: `POST /api/cart/update`

**In `apiReport1.md` Section 4.3:**  
`PUT /api/cart/{cart_item_id}` with body `{"quantity": 3}`

The Flutter client uses `PUT /api/cart/{cart_item_id}` which is RESTful and correct.

**Action Required:** Update `userReport.md` to reflect the correct HTTP method (`PUT`) and path.

---

## Issue #5 — Settings Response Key Name

**Severity:** LOW — May break QR display

**`apiReport1.md` shows:**
```json
{
  "data": {
    "sham_cash_qr": "...",
    "admin_phone": "+963..."
  }
}
```

**Flutter code reads:** `data['admin_phone']`

**Verify:** The backend actually returns `admin_phone` (not `contact_phone` as mentioned in `userReport.md` Section 4.4). If the key is `contact_phone`, the QR screen phone number will be null.

```dart
// flutter settings_provider.dart
_adminPhone = data['admin_phone'] as String?;
// If backend returns 'contact_phone', change to:
// _adminPhone = data['contact_phone'] as String?;
```

---

## Issue #6 — Missing Avatar Field in User Response

**Severity:** LOW — Profile screen shows generic icon

**`Report1.md` Section 2 documents:**  
User entity has `avatar` field.

**`apiReport1.md` Section 1.4 response:**
```json
{
  "data": {
    "id": 1, "name": "...", "email": "...", "phone": "...", "role": "user"
    // avatar field is MISSING from documented response
  }
}
```

**Action Required:** If avatar images are supported, add `avatar` to the `/me` response and the Flutter `UserModel` will need updating.

---

## Recommendations for Error Handling

The following HTTP status improvements would help the Flutter client:

| Scenario | Current | Recommended |
|----------|---------|-------------|
| Adding out-of-stock item to cart | Unknown | Return `422` with `errors.stock: ["Product is out of stock"]` |
| Cart is empty on checkout | `422` with `errors.cart` | Keep, well documented |
| Duplicate favorite | Unknown | Return `200 OK` (idempotent) or document the behavior |

---

## No Changes Required From Flutter Side

All Flutter code has been written to match `apiReport1.md` as the primary source of truth. The above issues only require **backend/documentation** changes, NOT Flutter code changes, **EXCEPT** for Issue #2 if the actual cart add path differs.

---

*End of fic.md — Backend AI Agent Action Required*
