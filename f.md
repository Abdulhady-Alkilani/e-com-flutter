إليك التقرير الذي يمكنك نسخه مباشرة وإعطائه للـ AI Agent المسؤول عن تطوير تطبيق الـ Flutter لتنفيذ التعديلات الجديدة الخاصة بألوان المنتجات:

***

```markdown
# Product Colors Feature - Flutter Implementation Report

## Overview
A new `colors` field has been added to the Products API specifically for the "Clothing" (البسة) category. This allows products to have multiple available colors (e.g., Red, Green, Brown Dress, etc.). 

## API Changes
The `ProductResource` API response has been updated to include a `colors` field.

- **Data Type:** Array of Strings (`List<String>`) or `null`.
- **Key:** `colors`

### Example JSON Response:
```json
{
  "id": 1,
  "name": "فستان سهرة",
  "description": "فستان سهرة مميز بألوان متعددة",
  "price": 250000,
  "stock": 10,
  "in_stock": true,
  "sizes": [
    { "size": "M", "quantity": 5 },
    { "size": "L", "quantity": 5 }
  ],
  "colors": [
    "أحمر",
    "فستان بني",
    "أخضر"
  ],
  "main_image": "http://domain.com/storage/products/image.jpg",
  "is_active": true,
  "category": {
    "id": 3,
    "name": "ألبسة"
  }
}
```

## Required Tasks for Flutter Agent

1. **Update Product Model:**
   - Add a `colors` variable to the `ProductModel`.
   - The type should be `List<String>? colors;`.
   - Include it in the `fromJson` and `toJson` serialization methods.

2. **Update Product Details Screen:**
   - On the product details page, check if the `colors` list is not null and not empty.
   - If colors are available, implement a UI component for color selection (e.g., a `Wrap` containing `ChoiceChip` widgets or custom color indicator buttons).
   - Ensure the user is required to select a color before adding the product to the cart (if applicable and colors are provided).

3. **Update Cart Logic (If Required):**
   - If the backend cart logic requires the selected color when adding a product, update the Cart Models and Cart API Requests to include the `selected_color` parameter.
   - Display the selected color in the cart items list.

4. **Product Card UI (Optional):**
   - If desired, display small color indicators on the `ProductCard` widget in the home or category screens to show users that the product comes in multiple colors.

**Note:** The `colors` field will primarily be populated for products in the Clothing category. For other product types (like Electronics), this field will likely be `null` or empty.
```