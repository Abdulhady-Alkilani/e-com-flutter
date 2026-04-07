// lib/screens/checkout/checkout_screen.dart
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';
import '../../core/constants/app_theme.dart';
import '../../providers/cart_provider.dart';
import '../../providers/checkout_provider.dart';
import '../../providers/settings_provider.dart';
import '../../widgets/custom_button.dart';
import '../../widgets/custom_text_field.dart';
import '../home/home_screen.dart';

class CheckoutScreen extends StatefulWidget {
  const CheckoutScreen({super.key});

  @override
  State<CheckoutScreen> createState() => _CheckoutScreenState();
}

class _CheckoutScreenState extends State<CheckoutScreen> {
  final _formKey = GlobalKey<FormState>();
  final _addressCtrl = TextEditingController();
  final _phoneCtrl = TextEditingController();
  final _notesCtrl = TextEditingController();

  bool _isFetchingLocation = false;

  Future<void> _getCurrentLocation() async {
    setState(() {
      _isFetchingLocation = true;
    });

    try {
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        throw 'خدمة الموقع غير مفعلة. يرجى تفعيلها أولاً.';
      }

      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          throw 'تم رفض صلاحية الوصول للموقع.';
        }
      }
      
      if (permission == LocationPermission.deniedForever) {
        throw 'صلاحية الوصول للموقع مرفوضة دائماً. يرجى تفعيلها من الإعدادات.';
      }

      Position position = await Geolocator.getCurrentPosition(
          desiredAccuracy: LocationAccuracy.high);

      List<Placemark> placemarks = await placemarkFromCoordinates(
          position.latitude, position.longitude);

      if (placemarks.isNotEmpty) {
        Placemark place = placemarks[0];
        String address = '';
        if (place.street != null && place.street!.isNotEmpty) address += '${place.street}, ';
        if (place.subLocality != null && place.subLocality!.isNotEmpty) address += '${place.subLocality}, ';
        if (place.locality != null && place.locality!.isNotEmpty) address += '${place.locality}, ';
        if (place.country != null && place.country!.isNotEmpty) address += place.country!;
        
        setState(() {
          _addressCtrl.text = address.endsWith(', ') ? address.substring(0, address.length - 2) : address;
        });
      } else {
        throw 'لم يتم العثور على عنوان للموقع الحالي.';
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(e.toString()),
          backgroundColor: AppColors.error,
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isFetchingLocation = false;
        });
      }
    }
  }

  @override
  void initState() {
    super.initState();
    // Get QR settings if not already loaded
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<SettingsProvider>().fetchSettings();
    });
  }

  @override
  void dispose() {
    _addressCtrl.dispose();
    _phoneCtrl.dispose();
    _notesCtrl.dispose();
    super.dispose();
  }

  Future<void> _submitOrder() async {
    if (!_formKey.currentState!.validate()) return;

    final checkoutProvider = context.read<CheckoutProvider>();
    if (checkoutProvider.receiptImage == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('يرجى رفع صورة إيصال الدفع أولاً'),
          backgroundColor: AppColors.error,
        ),
      );
      return;
    }

    final success = await checkoutProvider.submitOrder(
      shippingAddress: _addressCtrl.text.trim(),
      shippingPhone: _phoneCtrl.text.trim(),
      notes: _notesCtrl.text.trim(),
      receiptImage: checkoutProvider.receiptImage!,
    );

    if (!mounted) return;

    if (success) {
      // Clear cart after success
      context.read<CartProvider>().clearLocalCart();
      checkoutProvider.clearReceipt();

      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (_) => AlertDialog(
          shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20)),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.all(20),
                decoration: const BoxDecoration(
                  color: AppColors.success,
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.check, color: Colors.white, size: 40),
              ),
              const SizedBox(height: 20),
              const Text(
                'تم تقديم طلبك بنجاح! 🎉',
                style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textPrimary),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              const Text(
                'سيتم مراجعة إيصال الدفع والتأكيد خلال وقت قصير.',
                style: TextStyle(color: AppColors.textSecondary),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: () {
                  Navigator.of(context).pop();
                  Navigator.pushAndRemoveUntil(
                    context,
                    MaterialPageRoute(
                        builder: (_) => const HomeScreen()),
                    (route) => false,
                  );
                },
                child: const Text('العودة للرئيسية'),
              ),
            ],
          ),
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(checkoutProvider.errorMessage ??
              'فشل إرسال الطلب، يرجى المحاولة مجدداً'),
          backgroundColor: AppColors.error,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final cart = context.watch<CartProvider>();
    final settings = context.watch<SettingsProvider>();
    final checkout = context.watch<CheckoutProvider>();

    return Scaffold(
      appBar: AppBar(title: const Text('إتمام الطلب')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ─── Order Summary ─────────────────────────────────────────
              _SectionTitle(title: '📦 ملخص الطلب'),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                        color: Colors.black.withValues(alpha: 0.05), blurRadius: 6)
                  ],
                ),
                child: Column(
                  children: [
                    ...cart.items.map((item) => Padding(
                          padding: const EdgeInsets.symmetric(vertical: 4),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Expanded(
                                  child: Text(item.product.name,
                                      overflow: TextOverflow.ellipsis,
                                      style: const TextStyle(fontSize: 13))),
                              Text(
                                  '${item.quantity} × ${item.product.price.toStringAsFixed(0)}',
                                  style: const TextStyle(
                                      color: AppColors.textSecondary,
                                      fontSize: 13)),
                            ],
                          ),
                        )),
                    const Divider(height: 20),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text('المجموع:',
                            style: TextStyle(
                                fontWeight: FontWeight.bold, fontSize: 16)),
                        Text(
                          '${cart.totalPrice.toStringAsFixed(0)} ل.س',
                          style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 18,
                              color: AppColors.primary),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),

              // ─── Sham Cash QR ──────────────────────────────────────────
              _SectionTitle(title: '💳 ادفع عبر شام كاش'),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                        color: Colors.black.withValues(alpha: 0.05), blurRadius: 6)
                  ],
                ),
                child: Column(
                  children: [
                    if (settings.shamCashQr != null)
                      ClipRRect(
                        borderRadius: BorderRadius.circular(12),
                        child: CachedNetworkImage(
                          imageUrl: settings.shamCashQr!,
                          height: 180,
                          placeholder: (_, __) => const SizedBox(
                              height: 180,
                              child: Center(
                                  child: CircularProgressIndicator(
                                      color: AppColors.primary))),
                          errorWidget: (_, __, ___) =>
                              const Icon(Icons.qr_code, size: 100),
                        ),
                      )
                    else
                      Container(
                        height: 180,
                        decoration: BoxDecoration(
                          color: AppColors.shimmerBase,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.qr_code, size: 60,
                                  color: AppColors.textSecondary),
                              Text('رمز QR',
                                  style:
                                      TextStyle(color: AppColors.textSecondary))
                            ],
                          ),
                        ),
                      ),
                    const SizedBox(height: 12),
                    Text(
                      'امسح الرمز أعلاه لتحويل مبلغ ${cart.totalPrice.toStringAsFixed(0)} ل.س عبر تطبيق شام كاش',
                      style: const TextStyle(
                          color: AppColors.textSecondary, fontSize: 13),
                      textAlign: TextAlign.center,
                    ),
                    if (settings.adminPhone != null) ...[
                      const SizedBox(height: 6),
                      Text(
                        'أو التواصل: ${settings.adminPhone}',
                        style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            color: AppColors.primary),
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(height: 20),

              // ─── Upload Receipt ────────────────────────────────────────
              _SectionTitle(title: '📷 رفع إيصال الدفع'),
              GestureDetector(
                onTap: () => _showImagePickerDialog(context),
                child: Container(
                  height: 140,
                  width: double.infinity,
                  decoration: BoxDecoration(
                    color: checkout.receiptImage != null
                        ? Colors.transparent
                        : AppColors.primary.withValues(alpha: 0.06),
                    border: Border.all(
                      color: checkout.receiptImage != null
                          ? AppColors.success
                          : AppColors.primary,
                      style: BorderStyle.solid,
                      width: 2,
                    ),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: checkout.receiptImage != null
                      ? ClipRRect(
                          borderRadius: BorderRadius.circular(14),
                          child: Image.file(checkout.receiptImage!,
                              fit: BoxFit.cover),
                        )
                      : const Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.upload_file,
                                size: 44, color: AppColors.primary),
                            SizedBox(height: 8),
                            Text(
                              'انقر لرفع صورة إيصال التحويل',
                              style: TextStyle(
                                  color: AppColors.primary,
                                  fontWeight: FontWeight.bold),
                            ),
                          ],
                        ),
                ),
              ),
              const SizedBox(height: 20),

              // ─── Shipping Info ─────────────────────────────────────────
              _SectionTitle(title: '🏠 بيانات الشحن'),
              CustomTextField(
                label: 'عنوان الشحن',
                controller: _addressCtrl,
                prefixIcon: Icons.location_on_outlined,
                suffixIcon: IconButton(
                  icon: _isFetchingLocation
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(strokeWidth: 2))
                      : const Icon(Icons.my_location, color: AppColors.primary),
                  onPressed: _isFetchingLocation ? null : _getCurrentLocation,
                  tooltip: 'تحديد موقعي الحالي',
                ),
                validator: (v) =>
                    v == null || v.isEmpty ? 'العنوان مطلوب' : null,
              ),
              const SizedBox(height: 12),
              CustomTextField(
                label: 'جوال الاستلام',
                controller: _phoneCtrl,
                keyboardType: TextInputType.phone,
                prefixIcon: Icons.phone_outlined,
                validator: (v) =>
                    v == null || v.isEmpty ? 'رقم الجوال مطلوب' : null,
              ),
              const SizedBox(height: 12),
              CustomTextField(
                label: 'ملاحظات (اختياري)',
                controller: _notesCtrl,
                prefixIcon: Icons.note_outlined,
              ),
              const SizedBox(height: 28),

              CustomButton(
                text: 'تأكيد الطلب',
                icon: Icons.check_circle_outline,
                isLoading: checkout.isSubmitting,
                onPressed: _submitOrder,
              ),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }

  void _showImagePickerDialog(BuildContext context) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (_) => Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('اختر مصدر الصورة',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
            const SizedBox(height: 16),
            ListTile(
              leading: const Icon(Icons.photo_library,
                  color: AppColors.primary),
              title: const Text('من المعرض'),
              onTap: () {
                Navigator.pop(context);
                context.read<CheckoutProvider>().pickReceiptImage();
              },
            ),
            ListTile(
              leading:
                  const Icon(Icons.camera_alt, color: AppColors.primary),
              title: const Text('من الكاميرا'),
              onTap: () {
                Navigator.pop(context);
                context
                    .read<CheckoutProvider>()
                    .pickReceiptImageFromCamera();
              },
            ),
          ],
        ),
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  final String title;

  const _SectionTitle({required this.title});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Text(
        title,
        style: const TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.bold,
          color: AppColors.textPrimary,
        ),
      ),
    );
  }
}
