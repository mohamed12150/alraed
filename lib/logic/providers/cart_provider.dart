import 'package:flutter/material.dart';
import '../../models/cart_item.dart';
import '../../data/services/supabase_service.dart';

class CartProvider with ChangeNotifier {
  final SupabaseService _supabaseService = SupabaseService();
  List<CartItem> _items = [];
  bool _isLoading = false;
  String? _cartId;

  List<CartItem> get items => List.unmodifiable(_items);
  bool get isLoading => _isLoading;
  int get itemCount => _items.length;
  String? get cartId => _cartId;

  CartProvider() {
    _initAuthListener();
  }

  void _initAuthListener() {
    // Listen to auth changes to sync cart
    SupabaseService().client.auth.onAuthStateChange.listen((data) {
      final session = data.session;
      if (session != null) {
        fetchCart(session.user.id);
      } else {
        _items = [];
        _cartId = null;
        notifyListeners();
      }
    });
  }

  double get totalAmount {
    return _items.fold(0.0, (sum, item) => sum + item.totalPrice);
  }

  Future<void> fetchCart(String userId) async {
    _isLoading = true;
    // notifyListeners(); // Don't notify loading to prevent UI flickering

    try {
      final cartData = await _supabaseService.getCart(userId);
      debugPrint('Cart Data for user $userId: $cartData'); // Debug Log
      if (cartData != null) {
        _cartId = cartData['id'];
        final cartItems = (cartData['cart_items'] as List<dynamic>?)
            ?.map((item) {
              try {
                // debugPrint('Raw cart item: $item');
                final cartItem = CartItem.fromJson(item);
                // debugPrint('Parsed item: ${cartItem.title}, Option: ${cartItem.selectedOption}, Raw Cutting: ${item['cutting_methods']}');
                return cartItem;
              } catch (e) {
                debugPrint('Error parsing cart item: $e, Item: $item');
                return null;
              }
            })
            .where((item) => item != null)
            .cast<CartItem>()
            .toList();

        // Only update items if we got valid data back
        // This prevents clearing the cart if a momentary network error or parsing error occurs
        if (cartItems != null) {
          _items = cartItems;
        }
      } else {
        // If getCart returns null, it might mean the cart doesn't exist yet (which is fine)
        // OR it might be an error.
        // If it's just "no cart found", we can safely say empty.
        // But let's check if we have items locally - maybe keep them?
        // No, if the server says "no cart", we should probably respect that unless we are offline.
        // For now, to be safe against flickering, let's ONLY clear if we are sure.

        // _items = []; // COMMENTED OUT: Don't clear on null to prevent flicker if just a glitch
        // _cartId = null;
      }
    } catch (e) {
      debugPrint('Error fetching cart: $e');
    }

    _isLoading = false;
    notifyListeners();
  }

  Future<void> addItem({
    required String productId,
    required String title,
    required String image,
    required double price,
    required String weight,
    String? variantId,
    String? selectedOption,
    int? cuttingMethodId,
    String? userId,
  }) async {
    // Optimistic update
    final tempId = DateTime.now().toString();
    final existingIndex = _items.indexWhere(
      (item) =>
          item.productId == productId &&
          item.weight == weight &&
          item.selectedOption == selectedOption,
    );

    if (existingIndex >= 0) {
      _items[existingIndex].quantity++;
    } else {
      _items.add(
        CartItem(
          id: tempId,
          productId: productId,
          variantId: variantId,
          title: title,
          image: image,
          price: price,
          weight: weight,
          selectedOption: selectedOption,
          cuttingMethodId: cuttingMethodId,
        ),
      );
    }
    notifyListeners();

    if (userId != null) {
      try {
        String? finalVariantId = variantId;
        int? finalCuttingMethodId = cuttingMethodId;

        // Attempt to find variantId if missing but weight is provided
        if (finalVariantId == null && weight.isNotEmpty) {
          final variants = await _supabaseService.getProductVariants(productId);
          try {
            final variant = variants.firstWhere(
              (v) => v['attributes']?['weight'] == weight,
            );
            finalVariantId = variant['id'];
          } catch (_) {}
        }

        // Attempt to find cuttingMethodId if missing but selectedOption is provided
        if (finalCuttingMethodId == null && selectedOption != null) {
          final cuttingMethods = await _supabaseService
              .getProductCuttingMethods(productId);
          try {
            final cm = cuttingMethods.firstWhere((c) {
              final method = c['cutting_methods'] ?? c['cutting_method'];
              return method != null &&
                  (method['name_ar'] == selectedOption ||
                      method['name_en'] == selectedOption);
            });
            finalCuttingMethodId = cm['cutting_method_id'];
          } catch (_) {}
        }

        await _supabaseService.addToCart(
          userId: userId,
          productId: productId,
          variantId: finalVariantId,
          qty: 1,
          cuttingMethodId: finalCuttingMethodId,
        );
        debugPrint('Successfully added to Supabase cart');

        // Refresh cart to get real IDs and ensure sync
        await fetchCart(userId);
      } catch (e) {
        debugPrint('Error adding to Supabase cart: $e');
        // Rollback optimistic update if failed
        if (existingIndex >= 0) {
          _items[existingIndex].quantity--;
        } else {
          _items.removeWhere((item) => item.id == tempId);
        }
        notifyListeners();
      }
    }
  }

  Future<void> removeItem(String cartItemId, String? userId) async {
    final index = _items.indexWhere((item) => item.id == cartItemId);
    if (index >= 0) {
      _items.removeAt(index);
      notifyListeners();

      if (userId != null) {
        try {
          await _supabaseService.removeCartItem(cartItemId);
        } catch (e) {
          debugPrint('Error removing cart item: $e');
          // Revert?
        }
      }
    }
  }

  Future<void> updateQuantity(
    String cartItemId,
    int quantity,
    String? userId,
  ) async {
    final index = _items.indexWhere((item) => item.id == cartItemId);
    if (index >= 0) {
      if (quantity <= 0) {
        _items.removeAt(index);
      } else {
        _items[index].quantity = quantity;
      }
      notifyListeners();

      if (userId != null) {
        try {
          await _supabaseService.updateCartItemQuantity(cartItemId, quantity);
        } catch (e) {
          debugPrint('Error updating quantity: $e');
        }
      }
    }
  }

  Future<void> clearCart(String? userId, {String? cartId}) async {
    _items.clear();
    notifyListeners();

    if (userId != null && cartId != null) {
      try {
        await _supabaseService.clearCart(cartId);
      } catch (e) {
        debugPrint('Error clearing cart: $e');
      }
    }
  }

  bool isInCart(String productId, String weight, String? selectedOption) {
    return _items.any(
      (item) =>
          item.productId == productId &&
          item.weight == weight &&
          item.selectedOption == selectedOption,
    );
  }
}
