// lib/screens/cart/cart_screen.dart
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/constants/app_theme.dart';
import '../../providers/cart_provider.dart';
import '../../providers/auth_provider.dart';
import '../../widgets/custom_button.dart';
import '../checkout/checkout_screen.dart';
import '../auth/login_screen.dart';

class CartScreen extends StatefulWidget {
  const CartScreen({super.key});

  @override
  State<CartScreen> createState() => _CartScreenState();
}

class _CartScreenState extends State<CartScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final auth = context.read<AuthProvider>();
      if (auth.isAuthenticated) {
        context.read<CartProvider>().fetchCart();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.read<AuthProvider>();

    if (!auth.isAuthenticated) {
      return Scaffold(
        appBar: AppBar(title: const Text('سلة المشتريات')),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.shopping_cart_outlined,
                  size: 80, color: AppColors.textSecondary),
              const SizedBox(height: 16),
              const Text('يجب تسجيل الدخول لعرض السلة',
                  style: TextStyle(color: AppColors.textSecondary)),
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: () => Navigator.push(context,
                    MaterialPageRoute(builder: (_) => const LoginScreen())),
                child: const Text('تسجيل الدخول'),
              ),
            ],
          ),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(title: const Text('سلة المشتريات')),
      body: Consumer<CartProvider>(
        builder: (_, cart, __) {
          if (cart.isLoading && cart.items.isEmpty) {
            return const Center(
                child: CircularProgressIndicator(color: AppColors.primary));
          }
          if (cart.items.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.shopping_cart_outlined,
                      size: 80, color: AppColors.textSecondary),
                  const SizedBox(height: 16),
                  const Text('السلة فارغة',
                      style: TextStyle(
                          fontSize: 18, color: AppColors.textSecondary)),
                  const SizedBox(height: 8),
                  const Text('أضف بعض المنتجات للبدء',
                      style: TextStyle(color: AppColors.textSecondary)),
                ],
              ),
            );
          }
          return Column(
            children: [
              Expanded(
                child: ListView.separated(
                  padding: const EdgeInsets.all(16),
                  itemCount: cart.items.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 12),
                  itemBuilder: (_, i) {
                    final item = cart.items[i];
                    return Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.05),
                            blurRadius: 6,
                          ),
                        ],
                      ),
                      child: Row(
                        children: [
                          // Image
                          ClipRRect(
                            borderRadius: BorderRadius.circular(10),
                            child: CachedNetworkImage(
                              imageUrl: item.product.mainImage ?? '',
                              width: 80,
                              height: 80,
                              fit: BoxFit.cover,
                              errorWidget: (_, __, ___) => Container(
                                  width: 80,
                                  height: 80,
                                  color: AppColors.shimmerBase),
                            ),
                          ),
                          const SizedBox(width: 12),
                          // Info
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(item.product.name,
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                    style: const TextStyle(
                                        fontWeight: FontWeight.bold,
                                        fontSize: 14)),
                                const SizedBox(height: 4),
                                Text(
                                  '${item.product.price.toStringAsFixed(0)} ل.س',
                                  style: const TextStyle(
                                      color: AppColors.primary,
                                      fontWeight: FontWeight.bold),
                                ),
                              ],
                            ),
                          ),
                          // Quantity controls
                          Column(
                            children: [
                              Row(
                                children: [
                                  _QuantityBtn(
                                    icon: Icons.remove,
                                    onTap: () {
                                      if (item.quantity > 1) {
                                        cart.updateQuantity(
                                            item.cartItemId, item.quantity - 1);
                                      } else {
                                        cart.removeItem(item.cartItemId);
                                      }
                                    },
                                  ),
                                  Padding(
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 8),
                                    child: Text('${item.quantity}',
                                        style: const TextStyle(
                                            fontWeight: FontWeight.bold,
                                            fontSize: 16)),
                                  ),
                                  _QuantityBtn(
                                    icon: Icons.add,
                                    onTap: () => cart.updateQuantity(
                                        item.cartItemId, item.quantity + 1),
                                  ),
                                ],
                              ),
                              TextButton(
                                onPressed: () =>
                                    cart.removeItem(item.cartItemId),
                                style: TextButton.styleFrom(
                                    foregroundColor: AppColors.error),
                                child: const Text('حذف',
                                    style: TextStyle(fontSize: 12)),
                              ),
                            ],
                          ),
                        ],
                      ),
                    );
                  },
                ),
              ),
              // ─── Summary & Checkout ──────────────────────────────────
              Container(
                padding: const EdgeInsets.all(20),
                decoration: const BoxDecoration(
                  color: Colors.white,
                  borderRadius:
                      BorderRadius.vertical(top: Radius.circular(20)),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black12,
                      blurRadius: 10,
                      offset: Offset(0, -3),
                    ),
                  ],
                ),
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text('الإجمالي:',
                            style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: AppColors.textPrimary)),
                        Text(
                          '${cart.totalPrice.toStringAsFixed(0)} ل.س',
                          style: const TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                              color: AppColors.primary),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    CustomButton(
                      text: 'إتمام الطلب',
                      icon: Icons.payment,
                      onPressed: () => Navigator.push(
                        context,
                        MaterialPageRoute(
                            builder: (_) => const CheckoutScreen()),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

class _QuantityBtn extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;

  const _QuantityBtn({required this.icon, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 28,
        height: 28,
        decoration: BoxDecoration(
          border: Border.all(color: AppColors.border),
          borderRadius: BorderRadius.circular(6),
        ),
        child: Icon(icon, size: 16, color: AppColors.primary),
      ),
    );
  }
}
