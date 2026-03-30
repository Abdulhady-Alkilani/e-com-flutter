// lib/screens/home/home_screen.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/constants/app_theme.dart';
import '../../providers/auth_provider.dart';
import '../../providers/product_provider.dart';
import '../../providers/cart_provider.dart';
import '../../widgets/product_card.dart';
import '../../screens/cart/cart_screen.dart';
import '../../screens/profile/orders_screen.dart';
import '../../screens/auth/login_screen.dart';
import '../../screens/settings/network_settings_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _bottomNavIndex = 0;
  final _searchCtrl = TextEditingController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<ProductProvider>().fetchCategories();
      context.read<ProductProvider>().fetchProducts(refresh: true);
      final auth = context.read<AuthProvider>();
      if (auth.isAuthenticated) {
        context.read<CartProvider>().fetchCart();
      }
    });
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = context.read<AuthProvider>();

    final List<Widget> _screens = [
      const _HomeTab(),
      const _FavoriteTab(),
      const CartScreen(),
      authProvider.isAuthenticated
          ? const OrdersScreen()
          : const LoginScreen(),
    ];

    return Scaffold(
      body: IndexedStack(
        index: _bottomNavIndex,
        children: _screens,
      ),
      bottomNavigationBar: Consumer<CartProvider>(
        builder: (_, cart, __) => BottomNavigationBar(
          currentIndex: _bottomNavIndex,
          onTap: (i) => setState(() => _bottomNavIndex = i),
          items: [
            const BottomNavigationBarItem(
                icon: Icon(Icons.home_outlined),
                activeIcon: Icon(Icons.home),
                label: 'الرئيسية'),
            const BottomNavigationBarItem(
                icon: Icon(Icons.favorite_border),
                activeIcon: Icon(Icons.favorite),
                label: 'المفضلة'),
            BottomNavigationBarItem(
                icon: Badge(
                  label: Text('${cart.itemCount}'),
                  isLabelVisible: cart.itemCount > 0,
                  child: const Icon(Icons.shopping_cart_outlined),
                ),
                activeIcon: Badge(
                  label: Text('${cart.itemCount}'),
                  isLabelVisible: cart.itemCount > 0,
                  child: const Icon(Icons.shopping_cart),
                ),
                label: 'السلة'),
            const BottomNavigationBarItem(
                icon: Icon(Icons.receipt_long_outlined),
                activeIcon: Icon(Icons.receipt_long),
                label: 'طلباتي'),
          ],
        ),
      ),
    );
  }
}

// ─── Home Tab ──────────────────────────────────────────────────────────────
class _HomeTab extends StatelessWidget {
  const _HomeTab();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('المتجر الإلكتروني'),
        actions: [
          IconButton(
            icon: const Icon(Icons.settings),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const NetworkSettingsScreen()),
              );
            },
          ),
          Consumer<AuthProvider>(
            builder: (_, auth, __) => auth.isAuthenticated
                ? IconButton(
                    icon: const Icon(Icons.logout),
                    onPressed: () async {
                      await context.read<AuthProvider>().logout();
                      if (context.mounted) {
                        Navigator.pushReplacement(
                          context,
                          MaterialPageRoute(
                              builder: (_) => const LoginScreen()),
                        );
                      }
                    },
                  )
                : TextButton(
                    onPressed: () => Navigator.push(context,
                        MaterialPageRoute(builder: (_) => const LoginScreen())),
                    child: const Text('دخول',
                        style: TextStyle(color: Colors.white)),
                  ),
          ),
        ],
      ),
      body: Column(
        children: [
          // ─── Search Bar ───────────────────────────────────────────────
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
            child: TextField(
              decoration: InputDecoration(
                hintText: 'ابحث عن منتج...',
                prefixIcon:
                    const Icon(Icons.search, color: AppColors.primary),
                filled: true,
                fillColor: Colors.white,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
              ),
              onSubmitted: (q) =>
                  context.read<ProductProvider>().search(q),
            ),
          ),
          // ─── Categories ───────────────────────────────────────────────
          Consumer<ProductProvider>(
            builder: (_, prod, __) {
              if (prod.categories.isEmpty) return const SizedBox.shrink();
              return SizedBox(
                height: 46,
                child: ListView.builder(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  itemCount: prod.categories.length + 1,
                  itemBuilder: (_, i) {
                    if (i == 0) {
                      return _CategoryChip(
                        label: 'الكل',
                        isSelected: prod.selectedCategoryId == null,
                        onTap: () => prod.filterByCategory(null),
                      );
                    }
                    final cat = prod.categories[i - 1];
                    return _CategoryChip(
                      label: cat.name,
                      isSelected: prod.selectedCategoryId == cat.id,
                      onTap: () => prod.filterByCategory(cat.id),
                    );
                  },
                ),
              );
            },
          ),
          // ─── Products Grid ───────────────────────────────────────────
          Expanded(
            child: Consumer<ProductProvider>(
              builder: (_, prod, __) {
                if (prod.isLoading && prod.products.isEmpty) {
                  return const Center(
                      child: CircularProgressIndicator(
                          color: AppColors.primary));
                }
                if (prod.products.isEmpty) {
                  return const Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.search_off,
                            size: 64, color: AppColors.textSecondary),
                        SizedBox(height: 12),
                        Text('لا توجد منتجات',
                            style: TextStyle(color: AppColors.textSecondary)),
                      ],
                    ),
                  );
                }
                return GridView.builder(
                  padding: const EdgeInsets.all(12),
                  gridDelegate:
                      const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    childAspectRatio: 0.75,
                    crossAxisSpacing: 12,
                    mainAxisSpacing: 12,
                  ),
                  itemCount: prod.products.length,
                  itemBuilder: (_, i) =>
                      ProductCard(product: prod.products[i]),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _CategoryChip extends StatelessWidget {
  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  const _CategoryChip(
      {required this.label,
      required this.isSelected,
      required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        margin: const EdgeInsets.symmetric(horizontal: 4, vertical: 6),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.primary : Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected ? AppColors.primary : AppColors.border,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: isSelected ? Colors.white : AppColors.textSecondary,
            fontWeight:
                isSelected ? FontWeight.bold : FontWeight.normal,
            fontSize: 13,
          ),
        ),
      ),
    );
  }
}

// ─── Favorites Tab ─────────────────────────────────────────────────────────
class _FavoriteTab extends StatefulWidget {
  const _FavoriteTab();

  @override
  State<_FavoriteTab> createState() => _FavoriteTabState();
}

class _FavoriteTabState extends State<_FavoriteTab> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final auth = context.read<AuthProvider>();
      if (auth.isAuthenticated) {
        context.read<dynamic>().fetchFavorites();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.read<AuthProvider>();

    if (!auth.isAuthenticated) {
      return Scaffold(
        appBar: AppBar(title: const Text('المفضلة')),
        body: const Center(
          child: Text('يجب تسجيل الدخول لعرض المفضلة',
              style: TextStyle(color: AppColors.textSecondary)),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(title: const Text('المفضلة')),
      body: Consumer(
        builder: (context, favoriteProvider, _) {
          return const Center(
            child: Text('قائمة المفضلة',
                style: TextStyle(color: AppColors.textSecondary)),
          );
        },
      ),
    );
  }
}
