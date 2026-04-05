import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import 'package:iconsax/iconsax.dart';
import '../../models/product.dart';
import '../../logic/providers/cart_provider.dart';
import '../../logic/providers/language_provider.dart';
import '../../logic/providers/auth_provider.dart';

class ModernProductCard extends StatelessWidget {
  final Product product;

  const ModernProductCard({super.key, required this.product});

  @override
  Widget build(BuildContext context) {
    return Consumer3<CartProvider, LanguageProvider, AuthProvider>(
      builder: (context, cartProvider, languageProvider, authProvider, child) {
        final isArabic = languageProvider.isArabic;
        
        return GestureDetector(
          onTap: () {
            context.push('/product/${product.id}');
          },
          child: Container(
            decoration: BoxDecoration(
              color: Theme.of(context).cardColor,
              borderRadius: BorderRadius.circular(24),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(Theme.of(context).brightness == Brightness.light ? 0.03 : 0.2),
                  blurRadius: 15,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Product Image
                Expanded(
                  flex: 3,
                  child: Container(
                    width: double.infinity,
                    decoration: BoxDecoration(
                      borderRadius: const BorderRadius.vertical(
                        top: Radius.circular(24),
                      ),
                      image: DecorationImage(
                        image: product.imageUrl.startsWith('http')
                            ? NetworkImage(product.imageUrl) as ImageProvider
                            : AssetImage(product.imageUrl),
                        fit: BoxFit.cover,
                      ),
                    ),
                  ),
                ),
                // Product Details
                Expanded(
                  flex: 2,
                  child: Padding(
                    padding: const EdgeInsets.all(12),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              product.title,
                              style: Theme.of(context).textTheme.titleSmall?.copyWith(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 13,
                                  ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            const SizedBox(height: 2),
                            Text(
                              product.category,
                              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                    color: Theme.of(context).textTheme.bodySmall?.color?.withOpacity(0.6),
                                    fontSize: 11,
                                  ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Row(
                              children: [
                                Text(
                                  product.price.toStringAsFixed(0),
                                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                        color: Theme.of(context).primaryColor,
                                        fontWeight: FontWeight.bold,
                                      ),
                                ),
                                const SizedBox(width: 4),
                                Image.asset(
                                  'assets/images/sar.png',
                                  width: 16,
                                  height: 16,
                                  fit: BoxFit.contain,
                                  color: Theme.of(context).brightness == Brightness.dark ? Colors.white : null,
                                ),
                              ],
                            ),
                            GestureDetector(
                              onTap: () {
                                if (!authProvider.isLoggedIn) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      behavior: SnackBarBehavior.floating,
                                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                                      content: Text(
                                        isArabic
                                            ? 'يرجى تسجيل الدخول أولاً لإضافة منتجات للسلة'
                                            : 'Please login first to add products to cart',
                                      ),
                                      backgroundColor: Colors.orange,
                                    ),
                                  );
                                  context.push('/auth');
                                  return;
                                }

                                cartProvider.addItem(
                                  productId: product.id,
                                  title: product.title,
                                  image: product.imageUrl,
                                  price: product.price,
                                  weight: product.weights.isNotEmpty
                                      ? product.weights.first
                                      : '1 kg',
                                  selectedOption: product.options.isNotEmpty
                                      ? product.options.first
                                      : null,
                                  userId: authProvider.user?.id,
                                );
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    behavior: SnackBarBehavior.floating,
                                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                                    content: Text(
                                      isArabic
                                          ? 'تم إضافة المنتج إلى السلة'
                                          : 'Added to cart',
                                    ),
                                    duration: const Duration(seconds: 1),
                                  ),
                                );
                              },
                              child: Container(
                                padding: const EdgeInsets.all(8),
                                decoration: BoxDecoration(
                                  color: Theme.of(context).primaryColor,
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: const Icon(
                                  Iconsax.add,
                                  color: Colors.white,
                                  size: 18,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
