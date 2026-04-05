import 'package:flutter/material.dart';
import 'package:meatly/logic/providers/auth_provider.dart';
import 'package:meatly/logic/providers/orders_provider.dart';
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

  String selectedPaymentMethod = 'cash';
  bool isProcessing = false;

  // Constants
  final double deliveryFee = 20.0;
  final double taxRate = 0.15;

  @override
  void dispose() {
    _addressController.dispose();
    _phoneController.dispose();
    super.dispose();
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

    setState(() {
      isProcessing = true;
    });

    final cartProvider = Provider.of<CartProvider>(context, listen: false);

    // Calculate totals
    final subtotal = cartProvider.totalAmount;
    final tax = subtotal * taxRate;
    final total = subtotal + tax + deliveryFee;

    // Prepare order data for API
    final orderData = {
      'total_amount': total,
      'payment_method': selectedPaymentMethod,
      'status': 'pending',
      'delivery_fee': deliveryFee,
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
          final orderId = result['order_id'].toString();
          context.pushReplacement('/order-complete', extra: orderId);
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
    return Consumer2<LanguageProvider, CartProvider>(
      builder: (context, languageProvider, cartProvider, child) {
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
                                      ? 'الضريبة (15%)'
                                      : 'Tax (15%)',
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
                            id: 'cash',
                            title: languageProvider.isArabic
                                ? 'الدفع عند الاستلام'
                                : 'Cash on Delivery',
                            subtitle: languageProvider.isArabic
                                ? 'ادفع عند وصول الطلب'
                                : 'Pay when you receive',
                            icon: Iconsax.money,
                            context: context,
                          ),
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
