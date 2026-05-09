// lib/widgets/size_selector_widget.dart
import 'package:flutter/material.dart';
import '../core/constants/app_theme.dart';
import '../models/product_model.dart';

class SizeSelectorWidget extends StatefulWidget {
  final List<ProductSize> sizes;
  final Function(ProductSize) onSizeSelected;

  const SizeSelectorWidget({
    super.key,
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
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: AppColors.textPrimary,
          ),
        ),
        const SizedBox(height: 10),
        Wrap(
          spacing: 10,
          runSpacing: 10,
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
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                padding:
                    const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
                decoration: BoxDecoration(
                  color: isSelected
                      ? AppColors.primary
                      : isAvailable
                          ? Colors.white
                          : Colors.grey[200],
                  border: Border.all(
                    color: isSelected
                        ? AppColors.primary
                        : isAvailable
                            ? AppColors.border
                            : Colors.grey[300]!,
                    width: isSelected ? 2 : 1,
                  ),
                  borderRadius: BorderRadius.circular(10),
                  boxShadow: isSelected
                      ? [
                          BoxShadow(
                            color: AppColors.primary.withValues(alpha: 0.3),
                            blurRadius: 8,
                            offset: const Offset(0, 2),
                          ),
                        ]
                      : null,
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      size.size,
                      style: TextStyle(
                        color: isSelected
                            ? Colors.white
                            : isAvailable
                                ? AppColors.textPrimary
                                : AppColors.textSecondary,
                        fontWeight:
                            isSelected ? FontWeight.bold : FontWeight.w500,
                        fontSize: 14,
                        decoration:
                            isAvailable ? null : TextDecoration.lineThrough,
                      ),
                    ),
                    if (isAvailable) ...[
                      const SizedBox(height: 2),
                      Text(
                        'متوفر: ${size.quantity}',
                        style: TextStyle(
                          fontSize: 10,
                          color: isSelected
                              ? Colors.white70
                              : AppColors.textSecondary,
                        ),
                      ),
                    ],
                    if (!isAvailable) ...[
                      const SizedBox(height: 2),
                      Text(
                        'غير متوفر',
                        style: TextStyle(
                          fontSize: 10,
                          color: Colors.grey[500],
                        ),
                      ),
                    ],
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
