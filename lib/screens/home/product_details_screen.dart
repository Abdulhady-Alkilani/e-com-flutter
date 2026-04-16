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

    return CustomScrollView(
      slivers: [
        // ─── App Bar with Image ──────────────────────────────────────────
        SliverAppBar(
          expandedHeight: 300,
          pinned: true,
          backgroundColor: AppColors.primary,
          actions: [
            IconButton(
              icon: Icon(
                isFav ? Icons.favorite : Icons.favorite_border,
                color: isFav ? AppColors.accent : Colors.white,
              ),
              onPressed: () {
                if (!isAuth) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('يجب تسجيل الدخول أولاً')),
                  );
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
                        color: product.stock > 0
                            ? AppColors.success.withValues(alpha: 0.15)
                            : AppColors.error.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        product.stock > 0 ? 'متوفر' : 'نفذت الكمية',
                        style: TextStyle(
                          color: product.stock > 0
                              ? AppColors.success
                              : AppColors.error,
                          fontWeight: FontWeight.bold,
                          fontSize: 13,
                        ),
                      ),
                    ),
                  ],
                ),
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
                const SizedBox(height: 32),
                if (product.stock > 0)
                  Consumer<CartProvider>(
                    builder: (_, cart, __) => CustomButton(
                      text: 'أضف إلى السلة',
                      icon: Icons.add_shopping_cart,
                      isLoading: cart.isLoading,
                      onPressed: () async {
                        if (!isAuth) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                                content: Text('يجب تسجيل الدخول أولاً')),
                          );
                          return;
                        }
                        final ok = await context
                            .read<CartProvider>()
                            .addToCart(product.id);
                        if (mounted && ok) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('تمت الإضافة للسلة ✅'),
                              backgroundColor: AppColors.success,
                            ),
                          );
                        }
                      },
                    ),
                  ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
