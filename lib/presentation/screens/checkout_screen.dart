import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import 'package:meatly/logic/providers/auth_provider.dart';
import 'package:meatly/logic/providers/orders_provider.dart';
import 'package:meatly/logic/providers/shop_provider.dart';
import 'package:meatly/logic/providers/location_provider.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import 'package:iconsax/iconsax.dart';
import '../../logic/providers/cart_provider.dart';
import '../../logic/providers/language_provider.dart';
import '../../data/services/supabase_service.dart';

class CheckoutScreen extends StatefulWidget {
  const CheckoutScreen({super.key});

  @override
  State<CheckoutScreen> createState() => _CheckoutScreenState();
}

class _CheckoutScreenState extends State<CheckoutScreen> {
  final _formKey = GlobalKey<FormState>();
  final _addressController = TextEditingController();
  final _phoneController = TextEditingController();
  final SupabaseService _supabaseService = SupabaseService();

  String selectedPaymentMethod = 'bank_transfer';
  bool isProcessing = false;
  File? _receiptImage;

  @override
  void dispose() {
    _addressController.dispose();
    _phoneController.dispose();

    super.dispose();
  }

  Future<void> _pickReceiptImage() async {
    final languageProvider = Provider.of<LanguageProvider>(context, listen: false);
    final picker = ImagePicker();

    showModalBottomSheet(
      context: context,
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.photo_library),
              title: Text(languageProvider.isArabic ? 'من المعرض' : 'From Gallery'),
              onTap: () async {
                Navigator.pop(ctx);
                final picked = await picker.pickImage(source: ImageSource.gallery, imageQuality: 80);
                if (picked != null) setState(() => _receiptImage = File(picked.path));
              },
            ),
            ListTile(
              leading: const Icon(Icons.camera_alt),
              title: Text(languageProvider.isArabic ? 'من الكاميرا' : 'From Camera'),
              onTap: () async {
                Navigator.pop(ctx);
                final picked = await picker.pickImage(source: ImageSource.camera, imageQuality: 80);
                if (picked != null) setState(() => _receiptImage = File(picked.path));
              },
            ),
          ],
        ),
      ),
    );
  }

  void _processOrder() async {
    final languageProvider = Provider.of<LanguageProvider>(
      context,
      listen: false,
    );

    if (_formKey.currentState?.validate() != true) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            languageProvider.isArabic
                ? 'يرجى ملء جميع الحقول المطلوبة'
                : 'Please fill all required fields',
          ),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    if (selectedPaymentMethod == 'bank_transfer' && _receiptImage == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            languageProvider.isArabic
                ? 'يرجى رفع صورة إشعار التحويل'
                : 'Please upload the transfer receipt image',
          ),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    setState(() {
      isProcessing = true;
    });

    // Capture providers before async gap
    final cartProvider = Provider.of<CartProvider>(context, listen: false);
    final shopProvider = Provider.of<ShopProvider>(context, listen: false);

    // Upload receipt image if provided
    String? receiptImageUrl;
    if (_receiptImage != null) {
      receiptImageUrl = await _supabaseService.uploadReceiptImage(_receiptImage!.path);
    }

    // Calculate totals
    final subtotal = cartProvider.totalAmount;
    final tax = subtotal * shopProvider.taxRate;
    final total = subtotal + tax + shopProvider.deliveryFee;

    // Prepare order data for API
    final orderData = {
      'total_amount': total,
      'payment_method': selectedPaymentMethod,
      'status': 'pending',
      'delivery_fee': shopProvider.deliveryFee,
      'tax': tax,
      'subtotal': subtotal,

      // Store breakdown in metadata or use separate fields if available
      // For now, we will assume backend only takes total_amount, but we can store details in metadata if needed
      // Or we can add them as top-level fields if the schema supports it.
      // Let's assume we can pass them and if Supabase ignores them, fine.
      // Ideally, we should add 'subtotal', 'tax', 'delivery_fee' to orders table.
      // But since we can't easily change schema, we'll rely on total_amount.

      // Top-level fields for Schema v1
      'phone': _phoneController.text,
      'city': 'Riyadh',
      'address': _addressController.text,

      'payment_receipt_url': receiptImageUrl,

      'shipping_address': {
        'street': _addressController.text,
        'city': 'Riyadh',
        'phone': _phoneController.text,
      },

      'items': cartProvider.items.map((item) {
        final Map<String, dynamic> itemData = {
          'qty': item.quantity,
          'unit_price': item.price,
          'subtotal': item.totalPrice,
          'name_ar': item.title, // Snapshot of product name
          'variant_id': item.variantId,
          'metadata': {
            'weight': item.weight,
            'cutting_method': item.selectedOption,
          },
        };

        if (item.productId.isNotEmpty) {
          itemData['product_id'] = item.productId;
        }

        return itemData;
      }).toList(),
    };

    final result = await _supabaseService.placeOrder(orderData);
    print('Order placement result: $result');

    if (mounted) {
      setState(() {
        isProcessing = false;
      });

      if (result['success'] == true) {
        // Clear cart
        final authProvider = Provider.of<AuthProvider>(context, listen: false);
        if (authProvider.isLoggedIn) {
          // Refresh orders list
          Provider.of<OrdersProvider>(
            context,
            listen: false,
          ).fetchOrders(authProvider.user!.id);

          await cartProvider.clearCart(
            authProvider.user!.id,
            cartId: cartProvider.cartId,
          );
        } else {
          await cartProvider.clearCart(null);
        }

        if (mounted) {
          final orderNumber = result['order_number']?.toString() ?? result['order_id'].toString();
          context.pushReplacement('/order-complete', extra: orderNumber);
        }
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              languageProvider.isArabic
                  ? 'فشل في إتمام الطلب: ${result['message']}'
                  : 'Failed to place order: ${result['message']}',
            ),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Widget _buildSummaryRow(
    BuildContext context,
    String title,
    double amount, {
    bool isTotal = false,
    bool isDiscount = false,
  }) {
    final theme = Theme.of(context);
    final languageProvider = Provider.of<LanguageProvider>(
      context,
      listen: false,
    );

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            title,
            style: isTotal
                ? theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  )
                : theme.textTheme.bodyMedium?.copyWith(
                    color: theme.textTheme.bodyMedium?.color?.withOpacity(0.7),
                  ),
          ),
          Row(
            children: [
              Text(
                amount.toStringAsFixed(2),
                style: isTotal
                    ? theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: theme.primaryColor,
                      )
                    : theme.textTheme.bodyMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: isDiscount ? Colors.red : null,
                      ),
              ),
              const SizedBox(width: 4),
              Text(
                languageProvider.isArabic ? 'ر.س' : 'SAR',
                style: TextStyle(
                  fontSize: 12,
                  color: isTotal
                      ? theme.primaryColor
                      : theme.textTheme.bodySmall?.color,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildBankDetail(BuildContext context, String label, String value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
            color: Colors.grey[600],
          ),
        ),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Expanded(
              child: SelectableText(
                value,
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                  letterSpacing: 1.1,
                ),
              ),
            ),
            IconButton(
              icon: const Icon(Iconsax.copy, size: 20, color: Colors.blue),
              onPressed: () {
                Clipboard.setData(ClipboardData(text: value));
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(
                      Localizations.localeOf(context).languageCode == 'ar'
                          ? 'تم النسخ!'
                          : 'Copied!',
                    ),
                    duration: const Duration(seconds: 1),
                  ),
                );
              },
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildPaymentMethod({
    required String id,
    required String title,
    required String subtitle,
    required IconData icon,
    required BuildContext context,
  }) {
    final isSelected = selectedPaymentMethod == id;
    final theme = Theme.of(context);

    return InkWell(
      onTap: () {
        setState(() {
          selectedPaymentMethod = id;
        });
      },
      borderRadius: BorderRadius.circular(20),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isSelected
              ? theme.primaryColor.withOpacity(0.05)
              : theme.cardColor,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected
                ? theme.primaryColor
                : theme.dividerColor.withOpacity(0.1),
            width: isSelected ? 2 : 1,
          ),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: theme.primaryColor.withOpacity(0.1),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ]
              : null,
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: isSelected
                    ? theme.primaryColor
                    : theme.dividerColor.withOpacity(0.1),
                borderRadius: BorderRadius.circular(15),
              ),
              child: Icon(
                icon,
                color: isSelected
                    ? Colors.white
                    : theme.iconTheme.color?.withOpacity(0.7),
                size: 24,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: isSelected ? theme.primaryColor : null,
                    ),
                  ),
                  Text(
                    subtitle,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.textTheme.bodySmall?.color?.withOpacity(0.6),
                    ),
                  ),
                ],
              ),
            ),
            if (isSelected)
              Icon(Icons.check_circle, color: theme.primaryColor, size: 24)
            else
              Container(
                width: 24,
                height: 24,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: theme.dividerColor.withOpacity(0.3),
                    width: 2,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Consumer4<LanguageProvider, CartProvider, ShopProvider, LocationProvider>(
      builder: (context, languageProvider, cartProvider, shopProvider, locationProvider, child) {
        final deliveryFee = shopProvider.deliveryFee;
        final taxRate = shopProvider.taxRate;

        // Auto-fill address from GPS if empty
        if (_addressController.text.isEmpty && locationProvider.currentAddress.isNotEmpty) {
          _addressController.text = locationProvider.currentAddress;
        }

        return Directionality(
          textDirection: languageProvider.isArabic
              ? TextDirection.rtl
              : TextDirection.ltr,
          child: Scaffold(
            appBar: AppBar(
              title: Text(languageProvider.isArabic ? 'الدفع' : 'Checkout'),
              leading: IconButton(
                icon: Icon(
                  languageProvider.isArabic
                      ? Icons.arrow_forward
                      : Icons.arrow_back,
                ),
                onPressed: () => context.pop(),
              ),
            ),
            body: cartProvider.items.isEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Iconsax.shopping_cart,
                          size: 80,
                          color: Colors.grey[400],
                        ),
                        const SizedBox(height: 16),
                        Text(
                          languageProvider.isArabic
                              ? 'السلة فارغة'
                              : 'Your cart is empty',
                          style: Theme.of(context).textTheme.titleLarge,
                        ),
                        const SizedBox(height: 16),
                        ElevatedButton(
                          onPressed: () => context.go('/home'),
                          child: Text(
                            languageProvider.isArabic
                                ? 'العودة للتسوق'
                                : 'Continue Shopping',
                          ),
                        ),
                      ],
                    ),
                  )
                : SingleChildScrollView(
                    padding: const EdgeInsets.all(16),
                    child: Form(
                      key: _formKey,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Order Summary
                          Container(
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: Theme.of(context).cardColor,
                              borderRadius: BorderRadius.circular(24),
                              border: Border.all(
                                color: Theme.of(
                                  context,
                                ).dividerColor.withOpacity(0.1),
                              ),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  languageProvider.isArabic
                                      ? 'ملخص الطلب'
                                      : 'Order Summary',
                                  style: Theme.of(context).textTheme.titleLarge
                                      ?.copyWith(fontWeight: FontWeight.bold),
                                ),
                                const SizedBox(height: 16),
                                ListView.builder(
                                  shrinkWrap: true,
                                  physics: const NeverScrollableScrollPhysics(),
                                  itemCount: cartProvider.items.length,
                                  itemBuilder: (context, index) {
                                    final item = cartProvider.items[index];
                                    return Padding(
                                      padding: const EdgeInsets.only(
                                        bottom: 12,
                                      ),
                                      child: Row(
                                        children: [
                                          Container(
                                            width: 50,
                                            height: 50,
                                            decoration: BoxDecoration(
                                              borderRadius:
                                                  BorderRadius.circular(12),
                                              image: DecorationImage(
                                                image:
                                                    item.image.startsWith(
                                                      'http',
                                                    )
                                                    ? NetworkImage(item.image)
                                                          as ImageProvider
                                                    : AssetImage(item.image),
                                                fit: BoxFit.cover,
                                              ),
                                            ),
                                          ),
                                          const SizedBox(width: 12),
                                          Expanded(
                                            child: Column(
                                              crossAxisAlignment:
                                                  CrossAxisAlignment.start,
                                              children: [
                                                Text(
                                                  item.title,
                                                  style: Theme.of(context)
                                                      .textTheme
                                                      .bodyMedium
                                                      ?.copyWith(
                                                        fontWeight:
                                                            FontWeight.w600,
                                                      ),
                                                  maxLines: 1,
                                                  overflow:
                                                      TextOverflow.ellipsis,
                                                ),
                                                Text(
                                                  '${languageProvider.isArabic ? 'الوزن:' : 'Weight:'} ${item.weight} • ${languageProvider.isArabic ? 'الكمية:' : 'Qty:'} ${item.quantity}',
                                                  style: Theme.of(context)
                                                      .textTheme
                                                      .bodySmall
                                                      ?.copyWith(
                                                        color: Theme.of(context)
                                                            .textTheme
                                                            .bodySmall
                                                            ?.color
                                                            ?.withOpacity(0.6),
                                                      ),
                                                ),
                                              ],
                                            ),
                                          ),
                                          Row(
                                            children: [
                                              Text(
                                                item.totalPrice.toStringAsFixed(
                                                  0,
                                                ),
                                                style: Theme.of(context)
                                                    .textTheme
                                                    .titleMedium
                                                    ?.copyWith(
                                                      fontWeight:
                                                          FontWeight.bold,
                                                    ),
                                              ),
                                              const SizedBox(width: 4),
                                              Image.asset(
                                                'assets/images/sar.png',
                                                width: 16,
                                                height: 16,
                                                fit: BoxFit.contain,
                                                color:
                                                    Theme.of(
                                                          context,
                                                        ).brightness ==
                                                        Brightness.dark
                                                    ? Colors.white
                                                    : null,
                                              ),
                                            ],
                                          ),
                                        ],
                                      ),
                                    );
                                  },
                                ),
                                const Divider(),
                                const SizedBox(height: 8),

                                // Invoice Breakdown
                                _buildSummaryRow(
                                  context,
                                  languageProvider.isArabic
                                      ? 'المجموع الفرعي'
                                      : 'Subtotal',
                                  cartProvider.totalAmount,
                                ),
                                _buildSummaryRow(
                                  context,
                                  languageProvider.isArabic
                                      ? 'رسوم التوصيل'
                                      : 'Delivery Fee',
                                  deliveryFee,
                                ),
                                _buildSummaryRow(
                                  context,
                                  languageProvider.isArabic
                                      ? 'الضريبة (${(taxRate * 100).toStringAsFixed(0)}%)'
                                      : 'Tax (${(taxRate * 100).toStringAsFixed(0)}%)',
                                  cartProvider.totalAmount * taxRate,
                                ),
                                const Divider(),
                                _buildSummaryRow(
                                  context,
                                  languageProvider.isArabic
                                      ? 'الإجمالي الكلي'
                                      : 'Grand Total',
                                  cartProvider.totalAmount +
                                      deliveryFee +
                                      (cartProvider.totalAmount * taxRate),
                                  isTotal: true,
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 24),

                          // Shipping Information
                          Text(
                            languageProvider.isArabic
                                ? 'معلومات الشحن'
                                : 'Shipping Information',
                            style: Theme.of(context).textTheme.titleLarge
                                ?.copyWith(fontWeight: FontWeight.bold),
                          ),
                          const SizedBox(height: 16),

                          TextFormField(
                            controller: _addressController,
                            decoration: InputDecoration(
                              labelText: languageProvider.isArabic
                                  ? 'الحي / اسم الشارع'
                                  : 'District / Street Name',
                              border: const OutlineInputBorder(),
                              prefixIcon: const Icon(Iconsax.location),
                              suffixIcon: IconButton(
                                icon: locationProvider.isLoading
                                    ? const SizedBox(
                                        width: 20,
                                        height: 20,
                                        child: CircularProgressIndicator(strokeWidth: 2),
                                      )
                                    : const Icon(Iconsax.gps, color: Colors.blue),
                                onPressed: () async {
                                  await locationProvider.determinePosition();
                                  if (locationProvider.currentAddress.isNotEmpty) {
                                    _addressController.text = locationProvider.currentAddress;
                                  }
                                },
                                tooltip: languageProvider.isArabic
                                    ? 'تحديد موقعي الحالي'
                                    : 'Use current location',
                              ),
                            ),
                            validator: (value) {
                              if (value?.isEmpty ?? true) {
                                return languageProvider.isArabic
                                    ? 'العنوان مطلوب'
                                    : 'Address is required';
                              }
                              return null;
                            },
                          ),
                          const SizedBox(height: 16),

                          TextFormField(
                            controller: _phoneController,
                            keyboardType: TextInputType.phone,
                            decoration: InputDecoration(
                              labelText: languageProvider.isArabic
                                  ? 'رقم الهاتف'
                                  : 'Phone Number',
                              hintText: '05xxxxxxxx',
                              border: const OutlineInputBorder(),
                              prefixIcon: const Icon(Iconsax.call),
                            ),
                            validator: (value) {
                              if (value?.isEmpty ?? true) {
                                return languageProvider.isArabic
                                    ? 'رقم الهاتف مطلوب'
                                    : 'Phone number is required';
                              }
                              // Basic Saudi phone validation
                              if (value!.length < 10) {
                                return languageProvider.isArabic
                                    ? 'رقم الهاتف غير صحيح'
                                    : 'Invalid phone number';
                              }
                              return null;
                            },
                          ),
                          const SizedBox(height: 24),

                          // Payment Method
                          Text(
                            languageProvider.isArabic
                                ? 'طريقة الدفع'
                                : 'Payment Method',
                            style: Theme.of(context).textTheme.titleLarge
                                ?.copyWith(fontWeight: FontWeight.bold),
                          ),
                          const SizedBox(height: 16),

                          _buildPaymentMethod(
                            id: 'bank_transfer',
                            title: languageProvider.isArabic
                                ? 'تحويل بنكي'
                                : 'Bank Transfer',
                            subtitle: languageProvider.isArabic
                                ? 'حول المبلغ وارفقه برقم الإشعار'
                                : 'Transfer and provide reference',
                            icon: Iconsax.bank,
                            context: context,
                          ),

                          if (selectedPaymentMethod == 'bank_transfer') ...[
                            const SizedBox(height: 16),
                            Container(
                              padding: const EdgeInsets.all(16),
                              decoration: BoxDecoration(
                                color: Colors.blue.withOpacity(0.05),
                                borderRadius: BorderRadius.circular(20),
                                border: Border.all(
                                  color: Colors.blue.withOpacity(0.2),
                                ),
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  if (shopProvider.bankAccount.isNotEmpty)
                                    _buildBankDetail(
                                      context,
                                      languageProvider.isArabic ? 'رقم الحساب' : 'Account Number',
                                      shopProvider.bankAccount,
                                    ),
                                  if (shopProvider.bankAccount.isNotEmpty && shopProvider.bankIban.isNotEmpty)
                                    const Divider(height: 24),
                                  if (shopProvider.bankIban.isNotEmpty)
                                    _buildBankDetail(
                                      context,
                                      languageProvider.isArabic ? 'الآيبان' : 'IBAN',
                                      shopProvider.bankIban,
                                    ),
                                ],
                              ),
                            ),
                            const SizedBox(height: 16),
                            // Receipt image upload
                            GestureDetector(
                              onTap: _pickReceiptImage,
                              child: Container(
                                width: double.infinity,
                                constraints: const BoxConstraints(minHeight: 120),
                                decoration: BoxDecoration(
                                  color: Theme.of(context).cardColor,
                                  borderRadius: BorderRadius.circular(16),
                                  border: Border.all(
                                    color: _receiptImage != null
                                        ? Theme.of(context).primaryColor
                                        : Theme.of(context).dividerColor.withValues(alpha: 0.3),
                                    width: _receiptImage != null ? 2 : 1,
                                    style: _receiptImage != null ? BorderStyle.solid : BorderStyle.solid,
                                  ),
                                ),
                                child: _receiptImage != null
                                    ? ClipRRect(
                                        borderRadius: BorderRadius.circular(15),
                                        child: Stack(
                                          children: [
                                            Image.file(
                                              _receiptImage!,
                                              width: double.infinity,
                                              fit: BoxFit.cover,
                                            ),
                                            Positioned(
                                              top: 8,
                                              right: 8,
                                              child: GestureDetector(
                                                onTap: () => setState(() => _receiptImage = null),
                                                child: Container(
                                                  padding: const EdgeInsets.all(4),
                                                  decoration: const BoxDecoration(
                                                    color: Colors.red,
                                                    shape: BoxShape.circle,
                                                  ),
                                                  child: const Icon(Icons.close, color: Colors.white, size: 16),
                                                ),
                                              ),
                                            ),
                                          ],
                                        ),
                                      )
                                    : Column(
                                        mainAxisAlignment: MainAxisAlignment.center,
                                        children: [
                                          const SizedBox(height: 24),
                                          Icon(
                                            Iconsax.image,
                                            size: 40,
                                            color: Theme.of(context).primaryColor.withValues(alpha: 0.6),
                                          ),
                                          const SizedBox(height: 8),
                                          Text(
                                            languageProvider.isArabic
                                                ? 'ارفع صورة الإشعار'
                                                : 'Upload Receipt Image',
                                            style: Theme.of(context).textTheme.titleSmall?.copyWith(
                                              color: Theme.of(context).primaryColor,
                                              fontWeight: FontWeight.w600,
                                            ),
                                          ),
                                          const SizedBox(height: 4),
                                          Text(
                                            languageProvider.isArabic
                                                ? 'اضغط لاختيار الصورة من الجهاز'
                                                : 'Tap to pick from device',
                                            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                              color: Colors.grey,
                                            ),
                                          ),
                                          const SizedBox(height: 24),
                                        ],
                                      ),
                              ),
                            ),
                          ],
                          const SizedBox(height: 32),
                        ],
                      ),
                    ),
                  ),
            bottomNavigationBar: cartProvider.items.isNotEmpty
                ? Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.surface,
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.1),
                          blurRadius: 8,
                          offset: const Offset(0, -2),
                        ),
                      ],
                    ),
                    child: SizedBox(
                      width: double.infinity,
                      height: 56,
                      child: ElevatedButton(
                        onPressed: isProcessing ? null : _processOrder,
                        child: isProcessing
                            ? Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  const SizedBox(
                                    width: 20,
                                    height: 20,
                                    child: CircularProgressIndicator(
                                      color: Colors.white,
                                      strokeWidth: 2,
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  Text(
                                    languageProvider.isArabic
                                        ? 'جاري المعالجة...'
                                        : 'Processing...',
                                  ),
                                ],
                              )
                            : Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Text(
                                    '${languageProvider.isArabic ? 'تأكيد الطلب' : 'Confirm Order'} • ${(cartProvider.totalAmount + deliveryFee + (cartProvider.totalAmount * taxRate)).toStringAsFixed(2)}',
                                    style: const TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  const SizedBox(width: 4),
                                  Image.asset(
                                    'assets/images/sar.png',
                                    width: 16,
                                    height: 16,
                                    color: Colors.white,
                                    fit: BoxFit.contain,
                                  ),
                                ],
                              ),
                      ),
                    ),
                  )
                : null,
          ),
        );
      },
    );
  }
}
