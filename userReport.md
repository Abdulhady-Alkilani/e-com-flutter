

# Flutter Mobile App Blueprint: Single-Vendor E-Commerce (Manual Payment Integration)

## 1. Project Overview
**Goal:** Build a Flutter mobile application for an e-commerce platform.
**Backend:** Laravel 12 API using Sanctum for authentication.
**Core USP:** The app does not use a standard payment gateway. Instead, during checkout, the app fetches a "Sham Cash" QR code from the server, asks the user to pay externally, and requires the user to **upload a screenshot of the payment receipt** via a `multipart/form-data` API request to complete the order.

---

## 2. Technology Stack & Packages
*   **UI Framework:** Flutter (Latest Version).
*   **State Management:** `provider` (Strict requirement: Use MultiProvider architecture).
*   **Networking:** `dio` (Essential for handling `multipart/form-data` easily).
*   **Local Storage:** `flutter_secure_storage` (For Sanctum Bearer Token), `shared_preferences` (For app settings/theme).
*   **Media:** `image_picker` (To select payment receipt from gallery/camera).
*   **Image Loading:** `cached_network_image` (For products and QR code).
*   **Notifications:** `firebase_messaging`, `firebase_core`.
*   **Localization:** `flutter_localizations` (App must support Arabic RTL).

---

## 3. App Architecture & Folder Structure
*Instruction for AI: Adhere to the following feature-based folder structure inside `lib/`.*

```text
lib/
├── core/
│   ├── api/          # Dio client setup, interceptors (inject Bearer token)
│   ├── constants/    # App colors, endpoints URLs, text styles
│   └── utils/        # Helper functions, validators
├── models/           # Data models (User, Product, Order, Category, CartItem)
├── providers/        # State Management (AuthProvider, CartProvider, etc.)
├── screens/          # UI Screens (grouped by feature: auth, home, cart, checkout, profile)
├── widgets/          # Reusable UI components (ProductCard, CustomTextField, etc.)
└── main.dart         # Entry point, MultiProvider setup, Firebase init
```

---

## 4. State Management Strategy (Providers)

The app will rely on multiple specific providers to manage state efficiently.

### 4.1. `AuthProvider`
*   **State:** `User? currentUser`, `String? token`, `bool isLoading`.
*   **Methods:**
    *   `register(name, email, phone, password)`: Calls API, redirects to OTP screen.
    *   `verifyOtp(email, code)`: Calls API, saves Token to secure storage.
    *   `login(email, password)`: Fetches and saves Bearer Token.
    *   `logout()`: Clears token and notifies listeners.
    *   `checkAuthStatus()`: Reads token on app startup to auto-login.

### 4.2. `ProductProvider`
*   **State:** `List<Category> categories`, `List<Product> products`, `bool isLoading`.
*   **Methods:**
    *   `fetchCategories()`: `GET /api/categories`.
    *   `fetchProducts({int page, int? categoryId})`: `GET /api/products` with pagination.
    *   `toggleFavorite(int productId)`: `POST /api/favorites/toggle`.

### 4.3. `CartProvider`
*   **State:** `List<CartItem> cartItems`, `double totalAmount`.
*   **Methods:**
    *   `fetchCart()`: `GET /api/cart`.
    *   `addToCart(int productId, int quantity)`: `POST /api/cart/add`.
    *   `updateQuantity(int cartItemId, int quantity)`: `POST /api/cart/update`.
    *   `clearLocalCart()`: Called after successful order.

### 4.4. `CheckoutProvider` (Crucial Workflow)
*   **State:** `String? qrImageUrl`, `File? receiptImage`, `bool isSubmitting`.
*   **Methods:**
    *   `fetchPaymentSettings()`: `GET /api/settings` -> extracts `sham_cash_qr` URL.
    *   `pickReceiptImage()`: Uses `image_picker` to set `receiptImage`.
    *   `submitOrder(String address, String phone)`: See Section 5 for detailed logic.

### 4.5. `OrderProvider`
*   **State:** `List<Order> orderHistory`.
*   **Methods:**
    *   `fetchOrders()`: `GET /api/orders`.

---

## 5. The Checkout Workflow (Critical Agent Instruction)

This is the most important part of the app. Implement the `submitOrder` method in `CheckoutProvider` using `Dio` to send a `multipart/form-data` request.

**Step-by-Step UI Flow:**
1.  **Cart Screen:** User reviews items -> Clicks "Proceed to Checkout".
2.  **Shipping Screen:** User enters `address` and `phone` -> Clicks "Next".
3.  **Payment Screen:**
    *   *Action:* App calls `fetchPaymentSettings()` and displays the fetched QR Code image using `CachedNetworkImage`.
    *   *UI:* Text instructions: "Please scan the QR code, transfer the total amount via Sham Cash, and upload the screenshot below."
    *   *Action:* User taps "Select Image" -> `image_picker` opens gallery.
    *   *Action:* User taps "Confirm Order".

**API Submission Logic (Dio Snippet for AI Reference):**
```dart
Future<bool> submitOrder(String address, String phone, File receipt) async {
  try {
    isSubmitting = true;
    notifyListeners();

    String fileName = receipt.path.split('/').last;
    FormData formData = FormData.fromMap({
      'shipping_address': address,
      'shipping_phone': phone,
      'payment_receipt_image': await MultipartFile.fromFile(
        receipt.path,
        filename: fileName,
      ),
    });

    // Dio instance should already have the Bearer token in headers
    Response response = await dio.post('/api/orders', data: formData);

    if (response.statusCode == 201) {
      return true; // Success
    }
    return false;
  } on DioException catch (e) {
    // Handle validation errors (e.g., 422)
    return false;
  } finally {
    isSubmitting = false;
    notifyListeners();
  }
}
```

---

## 6. API Endpoint Mapping Reference

*   **Base URL:** Keep it configurable in `core/constants/api_constants.dart`.
*   **Auth Headers:** Every request (except register/login/categories/products) MUST include `Authorization: Bearer <token>` and `Accept: application/json`.
*   **Endpoints:**
    *   `POST /api/register` (Expects: name, email, phone, password)
    *   `POST /api/verify-email` (Expects: email, code)
    *   `POST /api/login` (Expects: email, password)
    *   `GET /api/settings` (Returns: `{"data": {"sham_cash_qr": "url...", "contact_phone": "..."}}`)
    *   `GET /api/categories`
    *   `GET /api/products` (Handle pagination)
    *   `GET /api/cart`
    *   `POST /api/cart/add`
    *   `POST /api/orders` (Multipart/form-data as explained above)
    *   `GET /api/orders` (History)

---

## 7. Firebase Cloud Messaging (FCM) Setup

*   Initialize Firebase in `main.dart`.
*   Request notification permissions on app startup.
*   Get FCM Token: `FirebaseMessaging.instance.getToken()`.
*   Send the FCM token to the backend upon login/registration (e.g., `POST /api/profile/fcm-token`).
*   Listen to foreground messages: Show a local SnackBar when the backend updates an order status (e.g., "Your order status changed to Shipped").

---

## 8. Execution Guidelines for AI Agent

**Agent Directive:** Build the Flutter app in the following phases:

1.  **Phase 1: Setup & Architecture:** Create the folder structure, configure `pubspec.yaml` with the required packages, setup the `Dio` client with an interceptor to inject the token from `flutter_secure_storage`.
2.  **Phase 2: Data Layer:** Create the Dart Data Models (`User`, `Product`, `Order`, `CartItem`) with `fromJson` and `toJson` methods.
3.  **Phase 3: State Management:** Implement all the `Providers` mentioned in Section 4. Ensure `notifyListeners()` is called correctly for UI reactivity. Set up `MultiProvider` in `main.dart`.
4.  **Phase 4: Authentication UI:** Build Register, OTP Verification, and Login screens. Handle API errors gracefully (show SnackBar).
5.  **Phase 5: Catalog UI:** Build Home Screen (Categories & Products list), Product Details Screen (with Image slider for gallery and handling external link).
6.  **Phase 6: Checkout Workflow (CRITICAL):** Carefully implement the Cart, Shipping, and Payment screens. Ensure the `image_picker` logic and the `FormData` submission to `/api/orders` works flawlessly.
7.  **Phase 7: User Profile & Orders:** Build the Order History screen to track status (`unpaid`, `paid`, `shipped`, etc.).
8.  **Phase 8: Polish:** Ensure full RTL (Arabic) support. Add loading indicators (`CircularProgressIndicator`) wherever `isLoading` is true in providers.
