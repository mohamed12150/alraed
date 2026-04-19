import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:iconsax/iconsax.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../logic/providers/language_provider.dart';
import '../../logic/providers/cart_provider.dart';
import '../../logic/providers/navigation_provider.dart';
import 'tabs/home_tab.dart';
import 'tabs/categories_tab.dart';
import 'tabs/cart_tab.dart';
import 'tabs/profile_tab.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  @override
  Widget build(BuildContext context) {
    return Consumer<LanguageProvider>(
      builder: (context, languageProvider, child) {
        final navigationProvider = context.watch<NavigationProvider>();
        final currentIndex = navigationProvider.currentIndex;
        final isArabic = languageProvider.isArabic;
        return Directionality(
          textDirection: isArabic ? TextDirection.rtl : TextDirection.ltr,
          child: Scaffold(
            backgroundColor: Theme.of(context).colorScheme.surface,
            body: IndexedStack(
              index: currentIndex,
              children: [
                const HomeTab(),
                const CategoriesTab(),
                const CartTab(),
                const ProfileTab(),
              ],
            ),
            floatingActionButton: FloatingActionButton(
              onPressed: () async {
                final Uri url = Uri.parse('https://wa.me/966575684434');
                if (!await launchUrl(url, mode: LaunchMode.externalApplication)) {
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(
                          isArabic ? 'تعذر فتح واتساب' : 'Could not launch WhatsApp',
                        ),
                      ),
                    );
                  }
                }
              },
              backgroundColor: const Color(0xFF25D366),
              child: const Icon(Icons.message, color: Colors.white),
            ),
            bottomNavigationBar: Consumer<CartProvider>(
              builder: (context, cartProvider, child) {
                return Container(
                  margin: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.surfaceContainer,
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [
                      BoxShadow(
                        color: Theme.of(context).shadowColor.withOpacity(0.1),
                        blurRadius: 10,
                        offset: const Offset(0, 5),
                      ),
                    ],
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(20),
                    child: BottomNavigationBar(
                      currentIndex: currentIndex,
                      onTap: (index) {
                        navigationProvider.setIndex(index);
                      },
                      type: BottomNavigationBarType.fixed,
                      backgroundColor: Colors.transparent,
                      elevation: 0,
                      selectedItemColor: Theme.of(context).colorScheme.primary,
                      unselectedItemColor: Theme.of(
                        context,
                      ).colorScheme.onSurface.withOpacity(0.5),
                      selectedLabelStyle: const TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 12,
                      ),
                      unselectedLabelStyle: const TextStyle(
                        fontWeight: FontWeight.w400,
                        fontSize: 12,
                      ),
                      items: [
                        BottomNavigationBarItem(
                          icon: const Icon(Iconsax.home_1),
                          activeIcon: const Icon(Iconsax.home_15),
                          label: isArabic ? 'الرئيسية' : 'Home',
                        ),
                        BottomNavigationBarItem(
                          icon: const Icon(Iconsax.category),
                          activeIcon: const Icon(Iconsax.category5),
                          label: isArabic ? 'التصنيفات' : 'Categories',
                        ),
                        BottomNavigationBarItem(
                          icon: Stack(
                            children: [
                              const Icon(Iconsax.shopping_cart),
                              if (cartProvider.itemCount > 0)
                                Positioned(
                                  right: 0,
                                  top: 0,
                                  child: Container(
                                    padding: const EdgeInsets.all(2),
                                    decoration: BoxDecoration(
                                      color: Theme.of(
                                        context,
                                      ).colorScheme.primary,
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    constraints: const BoxConstraints(
                                      minWidth: 14,
                                      minHeight: 14,
                                    ),
                                    child: Text(
                                      '${cartProvider.itemCount}',
                                      style: TextStyle(
                                        color: Theme.of(
                                          context,
                                        ).colorScheme.onPrimary,
                                        fontSize: 8,
                                        fontWeight: FontWeight.bold,
                                      ),
                                      textAlign: TextAlign.center,
                                    ),
                                  ),
                                ),
                            ],
                          ),
                          activeIcon: Stack(
                            children: [
                              const Icon(
                                Iconsax.shopping_cart,
                                color: null,
                              ), // Keep same icon shape
                              if (cartProvider.itemCount > 0)
                                Positioned(
                                  right: 0,
                                  top: 0,
                                  child: Container(
                                    padding: const EdgeInsets.all(2),
                                    decoration: BoxDecoration(
                                      color: Theme.of(
                                        context,
                                      ).colorScheme.primary,
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    constraints: const BoxConstraints(
                                      minWidth: 14,
                                      minHeight: 14,
                                    ),
                                    child: Text(
                                      '${cartProvider.itemCount}',
                                      style: TextStyle(
                                        color: Theme.of(
                                          context,
                                        ).colorScheme.onPrimary,
                                        fontSize: 8,
                                        fontWeight: FontWeight.bold,
                                      ),
                                      textAlign: TextAlign.center,
                                    ),
                                  ),
                                ),
                            ],
                          ),
                          label: isArabic ? 'السلة' : 'Cart',
                        ),
                        BottomNavigationBarItem(
                          icon: const Icon(Iconsax.profile_2user),
                          activeIcon: const Icon(Iconsax.profile_2user5),
                          label: isArabic ? 'الملف الشخصي' : 'Profile',
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
        );
      },
    );
  }
}
