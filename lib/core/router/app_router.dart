import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../models/product.dart';
import '../../logic/providers/shop_provider.dart';
import '../../presentation/screens/onboarding_screen.dart';
import '../../presentation/screens/splash_screen.dart';
import '../../presentation/screens/auth_screen.dart';
import '../../presentation/screens/otp_screen.dart';
import '../../presentation/screens/home_screen.dart';
import '../../presentation/screens/product_detail_screen.dart';
import '../../presentation/screens/checkout_screen.dart';
import '../../presentation/screens/order_complete_screen.dart';
import '../../presentation/screens/payment_methods_screen.dart';
import '../../presentation/screens/category_products_screen.dart';
import '../../presentation/screens/product_list_screen.dart';
import '../../presentation/screens/orders_screen.dart';
import '../../presentation/screens/maintenance_screen.dart';
import '../../presentation/screens/notifications_screen.dart';

class AppRouter {
  static final GoRouter router = GoRouter(
    initialLocation: '/splash',
    debugLogDiagnostics: true,
    routes: [
      GoRoute(
        path: '/splash',
        name: 'splash',
        builder: (context, state) => const SplashScreen(),
      ),
      GoRoute(
        path: '/onboarding',
        name: 'onboarding',
        builder: (context, state) => const OnboardingScreen(),
      ),
      GoRoute(
        path: '/auth',
        name: 'auth',
        builder: (context, state) => const AuthScreen(),
      ),
      GoRoute(
        path: '/otp',
        name: 'otp',
        builder: (context, state) {
          final extras = state.extra as Map<String, dynamic>;
          return OtpScreen(
            phoneNumber: extras['phoneNumber'] as String,
            isLogin: extras['isLogin'] as bool,
          );
        },
      ),
      GoRoute(
        path: '/home',
        name: 'home',
        builder: (context, state) => const HomeScreen(),
      ),
      GoRoute(
        path: '/product/:id',
        name: 'product',
        builder: (context, state) {
          final productId = state.pathParameters['id']!;
          final product = state.extra as Product?;

          if (product != null) {
            return ProductDetailScreen(product: product);
          }

          final shopProvider = context.read<ShopProvider>();
          try {
            final foundProduct = shopProvider.products.firstWhere(
              (p) => p.id == productId,
            );
            return ProductDetailScreen(product: foundProduct);
          } catch (e) {
            // Product not found, redirect to home or show error
            // For now, let's redirect to home with a frame callback to avoid build conflicts
            WidgetsBinding.instance.addPostFrameCallback((_) {
              context.go('/home');
            });
            return const Scaffold(
              body: Center(child: CircularProgressIndicator()),
            );
          }
        },
      ),
      GoRoute(
        path: '/checkout',
        name: 'checkout',
        builder: (context, state) => const CheckoutScreen(),
      ),
      GoRoute(
        path: '/order-complete',
        name: 'order-complete',
        builder: (context, state) {
          final orderNumber =
              state.extra as String? ??
              DateTime.now().millisecondsSinceEpoch.toString();
          return OrderCompleteScreen(orderNumber: orderNumber);
        },
      ),
      GoRoute(
        path: '/payment-methods',
        name: 'payment-methods',
        builder: (context, state) => const PaymentMethodsScreen(),
      ),
      GoRoute(
        path: '/category-products/:id',
        name: 'category-products',
        builder: (context, state) {
          final categoryId = state.pathParameters['id']!;
          final extra = state.extra as Map<String, dynamic>;
          final categoryName = extra['name'] as String;
          return CategoryProductsScreen(
            categoryId: categoryId,
            categoryName: categoryName,
          );
        },
      ),
      GoRoute(
        path: '/product-list/:type',
        name: 'product-list',
        builder: (context, state) {
          final listType = state.pathParameters['type']!;
          final extra = state.extra as Map<String, dynamic>;
          final title = extra['title'] as String;
          return ProductListScreen(listType: listType, title: title);
        },
      ),
      GoRoute(
        path: '/orders',
        name: 'orders',
        builder: (context, state) => const OrdersScreen(),
      ),
      GoRoute(
        path: '/maintenance',
        name: 'maintenance',
        builder: (context, state) => const MaintenanceScreen(),
      ),
      GoRoute(
        path: '/notifications',
        name: 'notifications',
        builder: (context, state) => const NotificationsScreen(),
      ),
    ],
  );
}
