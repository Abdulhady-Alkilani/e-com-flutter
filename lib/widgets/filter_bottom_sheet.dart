// lib/widgets/filter_bottom_sheet.dart
import 'package:flutter/material.dart';
import '../core/constants/app_theme.dart';
import '../providers/product_provider.dart';

class FilterBottomSheet extends StatefulWidget {
  final Function(FilterOptions) onApply;
  final FilterOptions? currentFilters;

  const FilterBottomSheet({
    super.key,
    required this.onApply,
    this.currentFilters,
  });

  @override
  State<FilterBottomSheet> createState() => _FilterBottomSheetState();
}

class _FilterBottomSheetState extends State<FilterBottomSheet> {
  late RangeValues _priceRange;
  late bool _inStockOnly;
  late String _sortBy;
  late String _sortOrder;

  @override
  void initState() {
    super.initState();
    _priceRange = RangeValues(
      widget.currentFilters?.minPrice ?? 0,
      widget.currentFilters?.maxPrice ?? 100000,
    );
    _inStockOnly = widget.currentFilters?.inStock ?? false;
    _sortBy = widget.currentFilters?.sortBy ?? 'created_at';
    _sortOrder = widget.currentFilters?.sortOrder ?? 'desc';
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Handle bar
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: AppColors.border,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Title
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'فلترة المنتجات',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textPrimary,
                  ),
                ),
                TextButton(
                  onPressed: () {
                    setState(() {
                      _priceRange = const RangeValues(0, 100000);
                      _inStockOnly = false;
                      _sortBy = 'created_at';
                      _sortOrder = 'desc';
                    });
                  },
                  child: const Text('إعادة تعيين',
                      style: TextStyle(color: AppColors.accent)),
                ),
              ],
            ),
            const SizedBox(height: 20),

            // Price Range
            const Text(
              'نطاق السعر (ل.س)',
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w600,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  '${_priceRange.start.toInt()} ل.س',
                  style: const TextStyle(
                    fontSize: 13,
                    color: AppColors.textSecondary,
                  ),
                ),
                Text(
                  '${_priceRange.end.toInt()} ل.س',
                  style: const TextStyle(
                    fontSize: 13,
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
            RangeSlider(
              values: _priceRange,
              min: 0,
              max: 100000,
              divisions: 100,
              activeColor: AppColors.primary,
              labels: RangeLabels(
                '${_priceRange.start.toInt()}',
                '${_priceRange.end.toInt()}',
              ),
              onChanged: (values) => setState(() => _priceRange = values),
            ),
            const SizedBox(height: 12),

            // In stock only
            Container(
              decoration: BoxDecoration(
                color: AppColors.background,
                borderRadius: BorderRadius.circular(12),
              ),
              child: SwitchListTile(
                title: const Text(
                  'المنتجات المتوفرة فقط',
                  style: TextStyle(fontSize: 14, color: AppColors.textPrimary),
                ),
                value: _inStockOnly,
                activeColor: AppColors.primary,
                activeTrackColor: AppColors.primary.withValues(alpha: 0.3),
                onChanged: (value) => setState(() => _inStockOnly = value),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Sort By
            const Text(
              'ترتيب حسب',
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w600,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              decoration: BoxDecoration(
                color: AppColors.background,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppColors.border),
              ),
              child: DropdownButton<String>(
                value: _sortBy,
                isExpanded: true,
                underline: const SizedBox.shrink(),
                items: const [
                  DropdownMenuItem(value: 'created_at', child: Text('الأحدث')),
                  DropdownMenuItem(value: 'price', child: Text('السعر')),
                  DropdownMenuItem(value: 'name', child: Text('الاسم')),
                ],
                onChanged: (value) => setState(() => _sortBy = value!),
              ),
            ),
            const SizedBox(height: 12),

            // Sort Order
            const Text(
              'اتجاه الترتيب',
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w600,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              decoration: BoxDecoration(
                color: AppColors.background,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppColors.border),
              ),
              child: DropdownButton<String>(
                value: _sortOrder,
                isExpanded: true,
                underline: const SizedBox.shrink(),
                items: const [
                  DropdownMenuItem(value: 'asc', child: Text('تصاعدي ↑')),
                  DropdownMenuItem(value: 'desc', child: Text('تنازلي ↓')),
                ],
                onChanged: (value) => setState(() => _sortOrder = value!),
              ),
            ),
            const SizedBox(height: 24),

            // Apply button
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () {
                  widget.onApply(FilterOptions(
                    minPrice: _priceRange.start > 0 ? _priceRange.start : null,
                    maxPrice:
                        _priceRange.end < 100000 ? _priceRange.end : null,
                    inStock: _inStockOnly ? true : null,
                    sortBy: _sortBy,
                    sortOrder: _sortOrder,
                  ));
                  Navigator.pop(context);
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: const Text(
                  'تطبيق الفلترة',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
              ),
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }
}
