# تقرير ربط الألوان بالصور - قسم Flutter

## ملخص التعديلات

تم ربط كل صورة (رئيسية وفرعية) بلون محدد من ألوان المنتج، بحيث يمكن عند الضغط على لون معين في التطبيق عرض الصورة المرتبطة بذلك اللون مباشرة.

> **ملاحظة:** هذه الميزة تعمل فقط للمنتجات التي تنتمي لأقسام تحتوي اسمها على **"لبسة"** أو **"ملابس"**.

---

## التعديلات على الـ API

### 1. استجابة المنتج (Product Response)

تمت إضافة حقلين جديدين في استجابة الـ API لأي منتج:

```json
{
  "id": 1,
  "name": "فستان أحمر",
  "description": "...",
  "price": 150000.00,
  "stock": 10,
  "in_stock": true,
  "sizes": [...],
  "colors": ["أحمر", "أخضر", "بنفسجي"],

  "main_image": "http://example.com/storage/products/image1.jpg",
  "main_image_color": "أحمر",          // <-- حقل جديد: لون الصورة الرئيسية

  "images": [
    {
      "id": 1,
      "image_path": "http://example.com/storage/products/gallery/img1.jpg",
      "color": "أحمر"                   // <-- حقل جديد: لون الصورة الفرعية
    },
    {
      "id": 2,
      "image_path": "http://example.com/storage/products/gallery/img2.jpg",
      "color": "أخضر"
    },
    {
      "id": 3,
      "image_path": "http://example.com/storage/products/gallery/img3.jpg",
      "color": "بنفسجي"
    }
  ]
}
```

### 2. الحقول الجديدة

| الحقل | الموقع | النوع | الوصف |
|-------|--------|-------|-------|
| `main_image_color` | جذر المنتج | `string \| null` | لون الصورة الرئيسية، يأخذ قيمة من مصفوفة `colors` |
| `color` | داخل كل عنصر في `images` | `string \| null` | لون الصورة الفرعية، يأخذ قيمة من مصفوفة `colors` |

---

## طريقة الاستخدام في Flutter

### 1. عرض ألوان المنتج كأزرار اختيار

```dart
// الحصول على ألوان المنتج
List<String> colors = List<String>.from(product['colors'] ?? []);

// المتغير الذي يحفظ اللون المختار
String? selectedColor;
```

### 2. عند الضغط على لون - عرض الصورة المرتبطة

```dart
void onColorSelected(String color) {
  setState(() {
    selectedColor = color;
  });

  // البحث عن الصورة الفرعية المرتبطة بهذا اللون
  final matchingImage = product['images'].firstWhere(
    (img) => img['color'] == color,
    orElse: () => null,
  );

  // البحث عن الصورة الرئيسية إذا كان اللون مطابقاً
  String? displayImage;
  if (product['main_image_color'] == color) {
    displayImage = product['main_image'];
  } else if (matchingImage != null) {
    displayImage = matchingImage['image_path'];
  }

  // تحديث الصورة المعروضة
  if (displayImage != null) {
    setState(() {
      currentImageUrl = displayImage;
    });
  }
}
```

### 3. بناء ويدجت اختيار الألوان

```dart
Widget buildColorSelector(Map<String, dynamic> product) {
  final colors = List<String>.from(product['colors'] ?? []);
  if (colors.isEmpty) return SizedBox.shrink();

  return Wrap(
    spacing: 8,
    children: colors.map((color) {
      final isSelected = selectedColor == color;
      return GestureDetector(
        onTap: () => onColorSelected(color),
        child: Container(
          padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          decoration: BoxDecoration(
            color: isSelected ? Colors.blue : Colors.grey[200],
            borderRadius: BorderRadius.circular(20),
            border: isSelected ? Border.all(color: Colors.blue, width: 2) : null,
          ),
          child: Text(
            color,
            style: TextStyle(
              color: isSelected ? Colors.white : Colors.black,
              fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
            ),
          ),
        ),
      );
    }).toList(),
  );
}
```

### 4. عرض صورة المنتج مع إمكانية التبديل باللون

```dart
Widget buildProductImage(Map<String, dynamic> product) {
  String imageUrl = product['main_image'] ?? '';

  // إذا تم اختيار لون، ابحث عن الصورة المناسبة
  if (selectedColor != null) {
    if (product['main_image_color'] == selectedColor) {
      imageUrl = product['main_image'];
    } else {
      final images = product['images'] as List?;
      final match = images?.firstWhere(
        (img) => img['color'] == selectedColor,
        orElse: () => null,
      );
      if (match != null) {
        imageUrl = match['image_path'];
      }
    }
  }

  return Image.network(imageUrl);
}
```

---

## ملاحظات مهمة لفريق Flutter

1. **التحقق من وجود الألوان:** ليس كل المنتجات تحتوي على ألوان. تحقق دائماً من أن `colors` ليست `null` أو فارغة قبل عرض ويدجت الألوان.

2. **التحقق من الأقسام:** هذه الميزة خاصة بمنتجات الألبسة فقط (أقسام تحتوي على "لبسة" أو "ملابس" في اسمها). لباقي المنتجات، الحقول ستكون `null`.

3. **الصورة الرئيسية مقابل الفرعية:**
   - `main_image` مع `main_image_color` هي الصورة الافتراضية
   - `images` هي الصور الإضافية، كل واحدة مرتبطة بلون عبر حقل `color`

4. **قد لا يكون لكل لون صورة:** بعض الألوان قد لا يكون لها صورة مرتبطة. في هذه الحالة يمكن عرض الصورة الرئيسية كبديل.

5. **ترتيب العملية:**
   - أولاً: عرض الصورة الرئيسية كصورة افتراضية
   - عندما يختار المستخدم لوناً: ابحث عن صورة مرتبطة بذلك اللون
   - إذا وُجدت صورة فرعية بنفس اللون: اعرضها
   - إذا كان اللون = `main_image_color`: اعرض الصورة الرئيسية
   - إذا لم توجد صورة: أبقِ الصورة الحالية كما هي
