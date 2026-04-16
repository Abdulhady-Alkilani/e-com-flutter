// lib/screens/profile/orders_screen.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/constants/app_theme.dart';
import '../../providers/order_provider.dart';
import '../../models/order_model.dart';
import 'order_details_screen.dart';
import '../../widgets/shimmer_loading.dart';

class OrdersScreen extends StatefulWidget {
  const OrdersScreen({super.key});

  @override
  State<OrdersScreen> createState() => _OrdersScreenState();
}

class _OrdersScreenState extends State<OrdersScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<OrderProvider>().fetchOrders(refresh: true);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('طلباتي')),
      body: Consumer<OrderProvider>(
        builder: (_, orderProvider, __) {
          if (orderProvider.isLoading && orderProvider.orders.isEmpty) {
            return const ShimmerList();
          }
          if (orderProvider.orders.isEmpty) {
            return const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.receipt_long_outlined,
                      size: 80, color: AppColors.textSecondary),
                  SizedBox(height: 16),
                  Text('لا توجد طلبات سابقة',
                      style: TextStyle(
                          fontSize: 18, color: AppColors.textSecondary)),
                ],
              ),
            );
          }
          return Column(
            children: [
              Expanded(
                child: RefreshIndicator(
                  onRefresh: () => orderProvider.fetchOrders(refresh: true),
                  color: AppColors.primary,
                  child: ListView.separated(
                    padding: const EdgeInsets.all(16),
                    itemCount: orderProvider.orders.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 12),
                    itemBuilder: (_, i) =>
                        _OrderCard(order: orderProvider.orders[i]),
                  ),
                ),
              ),
              if (orderProvider.lastPage > 1)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    border: Border(top: BorderSide(color: AppColors.border, width: 1)),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          minimumSize: Size.zero,
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                        ),
                        onPressed: orderProvider.hasPreviousPage
                            ? () => orderProvider.goToPreviousPage()
                            : null,
                        child: const Text('السابق'),
                      ),
                      Text(
                        'صفحة ${orderProvider.currentPage} من ${orderProvider.lastPage}',
                        style: const TextStyle(fontWeight: FontWeight.bold, color: AppColors.textPrimary),
                      ),
                      ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          minimumSize: Size.zero,
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                        ),
                        onPressed: orderProvider.hasNextPage
                            ? () => orderProvider.goToNextPage()
                            : null,
                        child: const Text('التالي'),
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

class _OrderCard extends StatelessWidget {
  final OrderModel order;

  const _OrderCard({required this.order});

  Color _statusColor(String status) {
    switch (status) {
      case 'unpaid':
        return AppColors.warning;
      case 'paid':
        return AppColors.success;
      case 'shipped':
        return AppColors.primary;
      case 'delivered':
        return AppColors.success;
      case 'cancelled':
        return AppColors.error;
      default:
        return AppColors.textSecondary;
    }
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => Navigator.push(
        context,
        MaterialPageRoute(
            builder: (_) => OrderDetailsScreen(orderId: order.id)),
      ),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.05),
              blurRadius: 8,
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.primary.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(Icons.shopping_bag_outlined,
                  color: AppColors.primary),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('طلب #${order.id}',
                      style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          color: AppColors.textPrimary)),
                  const SizedBox(height: 4),
                  Text(
                    '${order.totalAmount.toStringAsFixed(0)} ل.س',
                    style: const TextStyle(
                        color: AppColors.primary,
                        fontWeight: FontWeight.bold,
                        fontSize: 15),
                  ),
                ],
              ),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color:
                        _statusColor(order.status).withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    order.statusArabic,
                    style: TextStyle(
                      color: _statusColor(order.status),
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
                    ),
                  ),
                ),
                const SizedBox(height: 4),
                const Icon(Icons.arrow_forward_ios,
                    size: 14, color: AppColors.textSecondary),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
