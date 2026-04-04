// lib/screens/home/home_screen.dart
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/constants/app_theme.dart';
import '../../providers/auth_provider.dart';
import '../../providers/product_provider.dart';
import '../../providers/cart_provider.dart';
import '../../providers/favorite_provider.dart';
import '../../widgets/product_card.dart';
import '../../screens/cart/cart_screen.dart';
import '../../screens/profile/profile_screen.dart';
import '../../screens/auth/login_screen.dart';
import '../../screens/settings/network_settings_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _bottomNavIndex = 0;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<ProductProvider>().fetchCategories();
      context.read<ProductProvider>().fetchProducts(refresh: true);
      final auth = context.read<AuthProvider>();
      if (auth.isAuthenticated) {
        context.read<CartProvider>().fetchCart();
        context.read<FavoriteProvider>().fetchFavorites();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final List<Widget> screens = [
      const _HomeTab(),
      const _FavoriteTab(),
      const CartScreen(),
      const ProfileScreen(),
    ];

    return Scaffold(
      body: IndexedStack(
        index: _bottomNavIndex,
        children: screens,
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
                icon: Icon(Icons.person_outline),
                activeIcon: Icon(Icons.person),
                label: 'حسابي'),
          ],
        ),
      ),
    );
  }
}

// ─── Home Tab ──────────────────────────────────────────────────────────────
class _HomeTab extends StatefulWidget {
  const _HomeTab();

  @override
  State<_HomeTab> createState() => _HomeTabState();
}

class _HomeTabState extends State<_HomeTab> {
  final _searchCtrl = TextEditingController();

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('المتجر الإلكتروني'),
        actions: [
          IconButton(
            icon: const Icon(Icons.settings),
            tooltip: 'إعدادات الشبكة',
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
                    tooltip: 'تسجيل الخروج',
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
              controller: _searchCtrl,
              decoration: InputDecoration(
                hintText: 'ابحث عن منتج...',
                prefixIcon:
                    const Icon(Icons.search, color: AppColors.primary),
                suffixIcon: _searchCtrl.text.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear),
                        onPressed: () {
                          _searchCtrl.clear();
                          context.read<ProductProvider>().search('');
                          setState(() {});
                        },
                      )
                    : null,
                filled: true,
                fillColor: Colors.white,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
              ),
              onChanged: (q) {
                setState(() {});
                if (q.isEmpty) {
                  context.read<ProductProvider>().search('');
                }
              },
              onSubmitted: (q) =>
                  context.read<ProductProvider>().search(q),
            ),
          ),
          // ─── Categories Filter ─────────────────────────────────────────
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
                return RefreshIndicator(
                  color: AppColors.primary,
                  onRefresh: () =>
                      prod.fetchProducts(refresh: true),
                  child: GridView.builder(
                    padding: const EdgeInsets.all(12),
                    gridDelegate:
                        const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 2,
                      childAspectRatio: 0.75,
                      crossAxisSpacing: 12,
                      mainAxisSpacing: 12,
                    ),
                    itemCount: prod.products.length +
                        (prod.hasMorePages ? 1 : 0),
                    itemBuilder: (_, i) {
                      if (i == prod.products.length) {
                        // Load more trigger
                        WidgetsBinding.instance.addPostFrameCallback((_) {
                          prod.fetchProducts();
                        });
                        return const Center(
                            child: CircularProgressIndicator(
                                color: AppColors.primary));
                      }
                      return ProductCard(product: prod.products[i]);
                    },
                  ),
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
        // ✅ FIX: use correct type FavoriteProvider instead of dynamic
        context.read<FavoriteProvider>().fetchFavorites();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.read<AuthProvider>();

    if (!auth.isAuthenticated) {
      return Scaffold(
        appBar: AppBar(title: const Text('المفضلة')),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.favorite_border,
                  size: 80, color: AppColors.textSecondary),
              const SizedBox(height: 16),
              const Text('يجب تسجيل الدخول لعرض المفضلة',
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

    // ✅ FIX: use correct Consumer<FavoriteProvider> and display actual favorites list
    return Scaffold(
      appBar: AppBar(
        title: const Text('المفضلة'),
        actions: [
          Consumer<FavoriteProvider>(
            builder: (_, fav, __) => fav.favorites.isNotEmpty
                ? Padding(
                    padding: const EdgeInsets.only(left: 8),
                    child: Center(
                      child: Badge(
                        label: Text('${fav.favorites.length}'),
                        child: const Icon(Icons.favorite,
                            color: Colors.white),
                      ),
                    ),
                  )
                : const SizedBox.shrink(),
          ),
        ],
      ),
      body: Consumer<FavoriteProvider>(
        builder: (context, favoriteProvider, _) {
          if (favoriteProvider.isLoading) {
            return const Center(
                child: CircularProgressIndicator(color: AppColors.primary));
          }

          if (favoriteProvider.favorites.isEmpty) {
            return const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.favorite_border,
                      size: 80, color: AppColors.textSecondary),
                  SizedBox(height: 16),
                  Text('قائمة المفضلة فارغة',
                      style: TextStyle(
                          fontSize: 18, color: AppColors.textSecondary)),
                  SizedBox(height: 8),
                  Text('أضف منتجات تعجبك بالضغط على ❤️',
                      style: TextStyle(color: AppColors.textSecondary)),
                ],
              ),
            );
          }

          return RefreshIndicator(
            color: AppColors.primary,
            onRefresh: () => favoriteProvider.fetchFavorites(),
            child: GridView.builder(
              padding: const EdgeInsets.all(12),
              gridDelegate:
                  const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                childAspectRatio: 0.8,
                crossAxisSpacing: 12,
                mainAxisSpacing: 12,
              ),
              itemCount: favoriteProvider.favorites.length,
              itemBuilder: (_, i) {
                final product = favoriteProvider.favorites[i];
                return _FavoriteCard(
                  product: product,
                  onRemove: () =>
                      favoriteProvider.toggleFavorite(product.id),
                );
              },
            ),
          );
        },
      ),
    );
  }
}

class _FavoriteCard extends StatelessWidget {
  final dynamic product;
  final VoidCallback onRemove;

  const _FavoriteCard({required this.product, required this.onRemove});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.06),
            blurRadius: 8,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Image with remove button
          Stack(
            children: [
              ClipRRect(
                borderRadius:
                    const BorderRadius.vertical(top: Radius.circular(16)),
                child: CachedNetworkImage(
                  imageUrl: product.mainImage ?? '',
                  height: 130,
                  width: double.infinity,
                  fit: BoxFit.cover,
                  placeholder: (_, __) => Container(
                      color: AppColors.shimmerBase, height: 130),
                  errorWidget: (_, __, ___) => Container(
                    color: AppColors.shimmerBase,
                    height: 130,
                    child: const Icon(Icons.image_not_supported,
                        color: AppColors.textSecondary),
                  ),
                ),
              ),
              Positioned(
                top: 6,
                right: 6,
                child: GestureDetector(
                  onTap: onRemove,
                  child: Container(
                    padding: const EdgeInsets.all(6),
                    decoration: const BoxDecoration(
                      color: Colors.white,
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.favorite,
                        color: AppColors.accent, size: 18),
                  ),
                ),
              ),
            ],
          ),
          // Name
          Padding(
            padding: const EdgeInsets.all(8),
            child: Text(
              product.name,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: AppColors.textPrimary,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
