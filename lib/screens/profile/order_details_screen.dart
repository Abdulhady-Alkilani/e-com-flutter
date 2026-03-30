// lib/screens/profile/order_details_screen.dart
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import '../../core/constants/app_theme.dart';
import '../../models/order_model.dart';
import '../../providers/order_provider.dart';
import 'package:provider/provider.dart';

class OrderDetailsScreen extends StatefulWidget {
  final int orderId;

  const OrderDetailsScreen({super.key, required this.orderId});

  @override
  State<OrderDetailsScreen> createState() => _OrderDetailsScreenState();
}

class _OrderDetailsScreenState extends State<OrderDetailsScreen> {
  OrderModel? _order;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadOrder();
  }

  Future<void> _loadOrder() async {
    final order =
        await context.read<OrderProvider>().fetchOrderDetails(widget.orderId);
    if (mounted) setState(() {
      _order = order;
      _isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('تفاصيل الطلب #${widget.orderId}')),
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(color: AppColors.primary))
          : _order == null
              ? const Center(child: Text('لم يتم العثور على الطلب'))
              : _buildBody(),
    );
  }

  Widget _buildBody() {
    final order = _order!;
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Status
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.primary,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Column(
              children: [
                Text('رقم الطلب: #${order.id}',
                    style: const TextStyle(
                        color: Colors.white, fontWeight: FontWeight.bold)),
                const SizedBox(height: 4),
                Text(
                  'الحالة: ${order.statusArabic}',
                  style: const TextStyle(
                      color: Colors.white70, fontSize: 13),
                ),
                const SizedBox(height: 4),
                Text(
                  'المجموع: ${order.totalAmount.toStringAsFixed(0)} ل.س',
                  style: const TextStyle(
                      color: Colors.white,
                      fontSize: 20,
                      fontWeight: FontWeight.bold),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // Shipping Info
          if (order.shippingAddress != null || order.shippingPhone != null) ...[
            const Text('معلومات الشحن',
                style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                    color: AppColors.textPrimary)),
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (order.shippingAddress != null)
                    _InfoRow(
                        icon: Icons.location_on_outlined,
                        text: order.shippingAddress!),
                  if (order.shippingPhone != null)
                    _InfoRow(
                        icon: Icons.phone_outlined,
                        text: order.shippingPhone!),
                  if (order.notes != null)
                    _InfoRow(
                        icon: Icons.note_outlined, text: order.notes!),
                ],
              ),
            ),
            const SizedBox(height: 16),
          ],

          // Items
          const Text('المنتجات',
              style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                  color: AppColors.textPrimary)),
          const SizedBox(height: 8),
          Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Column(
              children: order.items.map((item) {
                return ListTile(
                  title: Text(item.productName,
                      style:
                          const TextStyle(fontWeight: FontWeight.bold,
                              fontSize: 14)),
                  subtitle: Text(
                      '${item.quantity} × ${item.price.toStringAsFixed(0)} ل.س'),
                  trailing: Text(
                    '${(item.quantity * item.price).toStringAsFixed(0)} ل.س',
                    style: const TextStyle(
                        color: AppColors.primary,
                        fontWeight: FontWeight.bold),
                  ),
                );
              }).toList(),
            ),
          ),

          // Payment Receipt
          if (order.paymentReceiptImage != null) ...[
            const SizedBox(height: 16),
            const Text('إيصال الدفع',
                style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                    color: AppColors.textPrimary)),
            const SizedBox(height: 8),
            ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: CachedNetworkImage(
                imageUrl: order.paymentReceiptImage!,
                width: double.infinity,
                height: 200,
                fit: BoxFit.cover,
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  final IconData icon;
  final String text;

  const _InfoRow({required this.icon, required this.text});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Icon(icon, size: 18, color: AppColors.primary),
          const SizedBox(width: 8),
          Expanded(
              child: Text(text,
                  style: const TextStyle(color: AppColors.textSecondary))),
        ],
      ),
    );
  }
}
