// lib/screens/home/product_details_screen.dart
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/constants/app_theme.dart';
import '../../models/product_model.dart';
import '../../providers/product_provider.dart';
import '../../providers/cart_provider.dart';
import '../../providers/favorite_provider.dart';
import '../../providers/auth_provider.dart';
import '../../widgets/custom_button.dart';
import '../../widgets/shimmer_loading.dart';
import '../../widgets/size_selector_widget.dart';
import '../../screens/cart/cart_screen.dart';
import '../../widgets/guest_login_dialog.dart';

class ProductDetailsScreen extends StatefulWidget {
  final int productId;

  const ProductDetailsScreen({super.key, required this.productId});

  @override
  State<ProductDetailsScreen> createState() => _ProductDetailsScreenState();
}

class _ProductDetailsScreenState extends State<ProductDetailsScreen> {
  ProductModel? _product;
  bool _isLoading = true;
  int _selectedImageIndex = 0;
  int _quantity = 1;
  ProductSize? _selectedSize;
  String? _selectedColor;
  late final PageController _imagePageController;

  @override
  void initState() {
    super.initState();
    _imagePageController = PageController(initialPage: _selectedImageIndex);
    _loadProduct();
  }

  @override
  void dispose() {
    _imagePageController.dispose();
    super.dispose();
  }

  Future<void> _loadProduct() async {
    final prod = await context
        .read<ProductProvider>()
        .fetchProductDetails(widget.productId);
    if (mounted) {
      setState(() {
        _product = prod;
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: _isLoading
          ? const ShimmerProductDetails()
          : _product == null
              ? const Center(child: Text('المنتج غير موجود'))
              : _buildBody(),
    );
  }

  Widget _buildBody() {
    final product = _product!;
    final allImages = [
      if (product.mainImage != null) product.mainImage!,
      ...product.images.map((i) => i.imagePath),
    ];
    final isFav = context.watch<FavoriteProvider>().isFavorite(product.id);
    final isAuth = context.read<AuthProvider>().isAuthenticated;

    void selectColor(String color) {
      final targetImage = product.imageUrlForColor(color);
      int targetIndex = -1;
      if (targetImage != null) {
        targetIndex = allImages.indexOf(targetImage);
      }
      setState(() {
        _selectedColor = color;
        if (targetIndex >= 0) {
          _selectedImageIndex = targetIndex;
        }
      });
      if (targetIndex >= 0) {
        _imagePageController.animateToPage(
          targetIndex,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeInOut,
        );
      }
    }

    return CustomScrollView(
      slivers: [
        // ─── App Bar with Image ──────────────────────────────────────────
        SliverAppBar(
          expandedHeight: 300,
          pinned: true,
          backgroundColor: AppColors.primary,
          actions: [
            Consumer<CartProvider>(
              builder: (_, cart, __) => IconButton(
                icon: Badge(
                  label: Text('${cart.itemCount}'),
                  isLabelVisible: cart.itemCount > 0,
                  child: const Icon(Icons.shopping_cart, color: Colors.white),
                ),
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const CartScreen()),
                  );
                },
              ),
            ),
            IconButton(
              icon: Icon(
                isFav ? Icons.favorite : Icons.favorite_border,
                color: isFav ? AppColors.accent : Colors.white,
              ),
              onPressed: () {
                if (!isAuth) {
                  showGuestLoginDialog(context,
                      message: 'يجب تسجيل الدخول لإضافة المنتجات للمفضلة');
                  return;
                }
                context.read<FavoriteProvider>().toggleFavorite(product.id);
              },
            ),
          ],
          flexibleSpace: FlexibleSpaceBar(
            background: allImages.isEmpty
                ? Container(color: AppColors.shimmerBase,
                    child: const Icon(Icons.image_not_supported,
                        size: 80, color: AppColors.textSecondary))
                : PageView.builder(
                    controller: _imagePageController,
                    onPageChanged: (i) => setState(() => _selectedImageIndex = i),
                    itemCount: allImages.length,
                    itemBuilder: (context, i) {
                      return Hero(
                        tag: i == 0 ? 'product_image_${product.id}' : 'product_image_extra_${product.id}_$i',
                        child: CachedNetworkImage(
                          imageUrl: allImages[i],
                          fit: BoxFit.cover,
                          placeholder: (_, __) =>
                              Container(color: AppColors.shimmerBase),
                          errorWidget: (_, __, ___) =>
                              Container(color: AppColors.shimmerBase),
                        ),
                      );
                    },
                  ),
          ),
        ),
        // ─── Thumbnail Row ───────────────────────────────────────────────
        if (allImages.length > 1)
          SliverToBoxAdapter(
            child: SizedBox(
              height: 70,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                itemCount: allImages.length,
                itemBuilder: (_, i) => GestureDetector(
                  onTap: () {
                    setState(() => _selectedImageIndex = i);
                    _imagePageController.animateToPage(
                      i,
                      duration: const Duration(milliseconds: 300),
                      curve: Curves.easeInOut,
                    );
                  },
                  child: Container(
                    margin: const EdgeInsets.only(right: 8),
                    width: 54,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: _selectedImageIndex == i
                            ? AppColors.primary
                            : AppColors.border,
                        width: 2,
                      ),
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(6),
                      child: CachedNetworkImage(
                        imageUrl: allImages[i],
                        fit: BoxFit.cover,
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        // ─── Product Info ────────────────────────────────────────────────
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  product.name,
                  style: const TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 8),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      '${product.price.toStringAsFixed(0)} ل.س',
                      style: const TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: AppColors.primary,
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 4),
                      decoration: BoxDecoration(
                        color: product.inStock
                            ? AppColors.success.withValues(alpha: 0.15)
                            : AppColors.error.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        product.inStock ? 'متوفر' : 'نفذت الكمية',
                        style: TextStyle(
                          color: product.inStock
                              ? AppColors.success
                              : AppColors.error,
                          fontWeight: FontWeight.bold,
                          fontSize: 13,
                        ),
                      ),
                    ),
                  ],
                ),

                // ─── Category badge ─────────────────────────────────────
                if (product.category != null) ...[
                  const SizedBox(height: 12),
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: AppColors.primary.withValues(alpha: 0.08),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      product.category!.name,
                      style: const TextStyle(
                        color: AppColors.primary,
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ],

                // ─── Size Selector ─────────────────────────────────────
                if (product.hasSizes) ...[
                  const SizedBox(height: 20),
                  SizeSelectorWidget(
                    sizes: product.sizes!,
                    onSizeSelected: (size) {
                      setState(() => _selectedSize = size);
                    },
                  ),
                ],

                // ─── Color Selector ─────────────────────────────────────
                if (product.hasColors) ...[
                  const SizedBox(height: 20),
                  const Text('اللون',
                      style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: AppColors.textPrimary)),
                  const SizedBox(height: 10),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: product.colors!.map((color) {
                      final isSelected = _selectedColor == color;
                      return ChoiceChip(
                        label: Text(color),
                        selected: isSelected,
                        onSelected: (_) {
                          if (isSelected) {
                            setState(() => _selectedColor = null);
                          } else {
                            selectColor(color);
                          }
                        },
                        selectedColor: AppColors.primary.withValues(alpha: 0.15),
                        side: BorderSide(
                          color: isSelected ? AppColors.primary : AppColors.border,
                          width: isSelected ? 2 : 1,
                        ),
                      );
                    }).toList(),
                  ),
                ],

                // ─── Description ────────────────────────────────────────
                if (product.description != null) ...[
                  const SizedBox(height: 20),
                  const Text('الوصف',
                      style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: AppColors.textPrimary)),
                  const SizedBox(height: 8),
                  Text(
                    product.description!,
                    style: const TextStyle(
                        fontSize: 14,
                        color: AppColors.textSecondary,
                        height: 1.6),
                  ),
                ],

                // ─── Stock info ─────────────────────────────────────────
                if (product.inStock) ...[
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      const Icon(Icons.inventory_2_outlined,
                          size: 18, color: AppColors.textSecondary),
                      const SizedBox(width: 6),
                      Text(
                        'المخزون الكلي: ${product.stock}',
                        style: const TextStyle(
                          fontSize: 13,
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ],

                // ─── Quantity selector ──────────────────────────────────
                if (product.inStock) ...[
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      const Text(
                        'الكمية:',
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      const SizedBox(width: 16),
                      _buildQuantityButton(
                        icon: Icons.remove,
                        onTap: _quantity > 1
                            ? () => setState(() => _quantity--)
                            : null,
                      ),
                      Padding(
                        padding:
                            const EdgeInsets.symmetric(horizontal: 16),
                        child: Text(
                          '$_quantity',
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: AppColors.textPrimary,
                          ),
                        ),
                      ),
                      _buildQuantityButton(
                        icon: Icons.add,
                        onTap: _quantity < product.stock
                            ? () => setState(() => _quantity++)
                            : null,
                      ),
                    ],
                  ),
                ],

                const SizedBox(height: 32),

                // ─── Add to Cart button ─────────────────────────────────
                if (product.inStock)
                  Consumer<CartProvider>(
                    builder: (_, cart, __) {
                      // Show error message if any
                      if (cart.errorMessage != null) {
                        WidgetsBinding.instance.addPostFrameCallback((_) {
                          if (mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text(cart.errorMessage!),
                                backgroundColor: AppColors.error,
                              ),
                            );
                            cart.clearError();
                          }
                        });
                      }

                      return CustomButton(
                        text: 'أضف إلى السلة',
                        icon: Icons.add_shopping_cart,
                        isLoading: cart.isLoading,
                        onPressed: () async {
                          if (!isAuth) {
                            showGuestLoginDialog(context,
                                message:
                                    'يجب تسجيل الدخول لإضافة المنتجات للسلة');
                            return;
                          }
                          // If product has sizes and none selected
                          if (product.hasSizes && _selectedSize == null) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('يرجى اختيار المقاس أولاً'),
                                backgroundColor: AppColors.warning,
                              ),
                            );
                            return;
                          }
                          if (product.hasColors && _selectedColor == null) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('يرجى اختيار اللون أولاً'),
                                backgroundColor: AppColors.warning,
                              ),
                            );
                            return;
                          }
                          final ok = await context
                              .read<CartProvider>()
                              .addToCart(
                                product.id,
                                quantity: _quantity,
                                selectedColor: _selectedColor,
                              );
                          if (mounted && ok) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('تمت الإضافة للسلة ✅'),
                                backgroundColor: AppColors.success,
                              ),
                            );
                          }
                        },
                      );
                    },
                  ),

                if (!product.inStock)
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    decoration: BoxDecoration(
                      color: AppColors.error.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Text(
                      'هذا المنتج غير متوفر حالياً',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: AppColors.error,
                        fontWeight: FontWeight.bold,
                        fontSize: 15,
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildQuantityButton({
    required IconData icon,
    VoidCallback? onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 34,
        height: 34,
        decoration: BoxDecoration(
          border: Border.all(
            color: onTap != null ? AppColors.primary : AppColors.border,
          ),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Icon(
          icon,
          size: 18,
          color: onTap != null ? AppColors.primary : AppColors.border,
        ),
      ),
    );
  }
}
