import 'dart:io';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class SupabaseService {
  final SupabaseClient client = Supabase.instance.client;

  String _aliasFromPhone(String phone) {
    final cleaned = phone.replaceAll(RegExp(r'[^0-9+]'), '');
    return '$cleaned@alraed.local';
  }

  Future<Map<String, dynamic>> register(
    String name,
    String phone,
    String password,
  ) async {
    try {
      // Check if user exists (RPC call or specialized query if available)
      // Since standard Supabase Auth doesn't expose 'check email' directly for security,
      // we can rely on the signUp response. However, if 'User Enumeration Protection' is ON,
      // signUp returns success even for existing users.
      //
      // Workaround: Try to signIn first? No, that requires password.
      // Better Workaround: If you have a 'profiles' table that is public readable, check it.

      try {
        final existingUser = await client
            .from('profiles')
            .select('id')
            .eq('phone_number', phone)
            .maybeSingle();

        if (existingUser != null) {
          return {'success': false, 'message': 'User already registered'};
        }
      } catch (_) {
        // If checking profiles fails (e.g. RLS), proceed to signUp attempt
      }

      final emailAlias = _aliasFromPhone(phone);

      final res = await client.auth.signUp(
        email: emailAlias,
        password: password,
        data: {'full_name': name, 'phone_number': phone},
      );

      // If user exists and protection is OFF, it throws error caught below.
      // If user exists and protection is ON, it might return a session with fake user or null user identity
      // But typically res.user is returned.
      // Checking res.user?.identities can sometimes reveal if it's a new user (empty if existing).

      if (res.user != null &&
          res.user!.identities != null &&
          res.user!.identities!.isEmpty) {
        return {'success': false, 'message': 'User already registered'};
      }

      if (res.user == null) {
        return {'success': false, 'message': 'Registration failed'};
      }

      final session = res.session;
      return {
        'success': true,
        'user': {
          'id': res.user!.id,
          'email': res.user!.email,
          'name': name,
        },
        'token': session?.accessToken,
      };
    } on AuthException catch (e) {
      return {'success': false, 'message': e.message, 'code': e.statusCode};
    } catch (e) {
      return {'success': false, 'message': e.toString()};
    }
  }

  Future<Map<String, dynamic>> login(String phone, String password) async {
    try {
      final emailAlias = _aliasFromPhone(phone);

      final res = await client.auth.signInWithPassword(
        email: emailAlias,
        password: password,
      );

      if (res.user == null) {
        return {'success': false, 'message': 'Login failed'};
      }

      String name =
          res.user!.userMetadata?['full_name'] ?? phone;
      try {
        final profileRes = await client
            .from('profiles')
            .select()
            .eq('id', res.user!.id)
            .maybeSingle();

        if (profileRes != null && profileRes['full_name'] != null) {
          name = profileRes['full_name'];
        }
      } catch (_) {}

      final session = res.session;
      return {
        'success': true,
        'user': {'id': res.user!.id, 'email': res.user!.email, 'name': name},
        'token': session?.accessToken,
      };
    } on AuthException catch (e) {
      return {'success': false, 'message': e.message, 'code': e.statusCode};
    } catch (e) {
      return {'success': false, 'message': e.toString()};
    }
  }

  Future<List<Map<String, dynamic>>> getBanners() async {
    try {
      final res = await client
          .from('banners')
          .select()
          .eq('is_active', true)
          .order('display_order', ascending: true);
      final data = res as List<dynamic>?;
      if (data == null) return [];
      return data.cast<Map<String, dynamic>>();
    } catch (_) {
      return [];
    }
  }

  Future<String?> uploadReceiptImage(String filePath) async {
    try {
      final user = client.auth.currentUser;
      if (user == null) return null;

      final file = File(filePath);
      final fileExt = filePath.split('.').last.toLowerCase();
      final fileName = '${user.id}/${DateTime.now().millisecondsSinceEpoch}.$fileExt';

      await client.storage.from('receipts').upload(fileName, file);

      return client.storage.from('receipts').getPublicUrl(fileName);
    } catch (e) {
      print('Error uploading receipt image: $e');
      return null;
    }
  }

  Future<Map<String, dynamic>> placeOrder(
    Map<String, dynamic> orderData,
  ) async {
    try {
      final user = client.auth.currentUser;
      if (user == null) {
        return {'success': false, 'message': 'User not logged in'};
      }

      // 1. Create Order
      final orderInsert = {
        'user_id': user.id,
        'total_amount': orderData['total_amount'],
        'payment_method': orderData['payment_method'],
        'status': orderData['status'] ?? 'pending',
        'phone': orderData['phone'],
        'city': orderData['city'],
        'address': orderData['address'],
        'shipping_address': orderData['shipping_address'],
        if (orderData['payment_receipt_url'] != null)
          'payment_receipt_url': orderData['payment_receipt_url'],
      };

      final orderRes = await client
          .from('orders')
          .insert(orderInsert)
          .select()
          .single();

      final orderId = orderRes['id'];
      final orderNumber = orderRes['order_number']?.toString() ?? orderId.toString();

      // 2. Create Order Items
      final items = (orderData['items'] as List).map((item) {
        return {
          'order_id': orderId,
          'product_id': item['product_id'],
          'variant_id': item['variant_id'],
          'name_ar': item['name_ar'],
          'qty': item['qty'],
          'unit_price': item['unit_price'],
          'subtotal': item['subtotal'],
          'metadata': item['metadata'],
        };
      }).toList();

      await client.from('order_items').insert(items);

      // 3. Update product sales count
      for (var item in items) {
        try {
          final productId = item['product_id'];
          final qty = item['qty'] as int;

          // Fetch current sales count
          final productRes = await client
              .from('products')
              .select('sales_count')
              .eq('id', productId)
              .maybeSingle();

          if (productRes != null) {
            final currentSales = productRes['sales_count'] as int? ?? 0;
            
            // Update with new count
            await client
                .from('products')
                .update({'sales_count': currentSales + qty})
                .eq('id', productId);
          }
        } catch (e) {
          print('Error updating sales count for product ${item['product_id']}: $e');
          // Continue with other items even if one fails
        }
      }

      return {'success': true, 'order_id': orderId, 'order_number': orderNumber};
    } catch (e) {
      print('Error placing order: $e');
      return {'success': false, 'message': e.toString()};
    }
  }

  Future<List<Map<String, dynamic>>> getOrders(String userId) async {
    try {
      final res = await client
          .from('orders')
          .select('*, order_items(*)')
          .eq('user_id', userId)
          .order('created_at', ascending: false);

      final data = res as List<dynamic>?;
      if (data == null) return [];
      return data.cast<Map<String, dynamic>>();
    } catch (_) {
      return [];
    }
  }

  Future<List<Map<String, dynamic>>> getSpecialOffers() async {
    try {
      final res = await client
          .from('special_offers')
          .select()
          .eq('is_active', true)
          .order('display_order', ascending: true);
      final data = res as List<dynamic>?;
      if (data == null) return [];
      return data.cast<Map<String, dynamic>>();
    } catch (_) {
      return [];
    }
  }

  Future<Map<String, dynamic>?> getAppSettings() async {
    try {
      final res = await client
          .from('app_settings')
          .select()
          .eq('id', 1)
          .maybeSingle();
      return res;
    } catch (_) {
      return null;
    }
  }

  Future<Map<String, dynamic>?> getProfile(String userId) async {
    try {
      final res = await client
          .from('profiles')
          .select()
          .eq('id', userId)
          .maybeSingle();
      return res;
    } catch (_) {
      return null;
    }
  }

  Future<bool> updateProfile(
    String userId,
    Map<String, dynamic> updates,
  ) async {
    try {
      await client.from('profiles').upsert({'id': userId, ...updates});
      return true;
    } catch (e) {
      return false;
    }
  }

  Future<List<Map<String, dynamic>>> getCuttingMethods() async {
    try {
      final res = await client
          .from('cutting_methods')
          .select()
          .order('position', ascending: true);
      final data = res as List<dynamic>?;
      if (data == null) return [];
      return data.cast<Map<String, dynamic>>();
    } catch (_) {
      return [];
    }
  }

  Future<List<Map<String, dynamic>>> getProductCuttingMethods(
    String productId,
  ) async {
    try {
      final res = await client
          .from('product_cutting_methods')
          .select('*, cutting_methods(*)')
          .eq('product_id', productId);
      final data = res as List<dynamic>?;
      if (data == null) return [];

      // debugPrint('Fetched cutting methods for $productId: $data');
      return data.cast<Map<String, dynamic>>();
    } catch (e) {
      debugPrint('Error fetching product cutting methods: $e');
      return [];
    }
  }

  Future<List<Map<String, dynamic>>> getCategories() async {
    try {
      final res = await client.from('categories').select();
      final data = res as List<dynamic>?;
      if (data == null) return [];
      return data.cast<Map<String, dynamic>>();
    } catch (_) {
      return [];
    }
  }

  Future<List<Map<String, dynamic>>> getProducts({String? categoryId}) async {
    try {
      // Fetch products with their cutting methods AND category details
      var query = client
          .from('products')
          .select(
            '*, categories(name_ar, name_en), product_cutting_methods(cutting_methods(*)), product_images(*)',
          );

      if (categoryId != null) {
        query = query.eq('category_id', categoryId);
      }

      final res = await query;
      final data = res as List<dynamic>?;
      if (data == null) return [];

      return data.map((item) {
        final product = Map<String, dynamic>.from(item);
        // Flatten cutting methods into options list for the current Product model
        final cuttingMethods =
            item['product_cutting_methods'] as List<dynamic>? ?? [];
        product['options'] = cuttingMethods
            .map((cm) {
              final method = cm['cutting_methods'];
              return method != null
                  ? method['name_ar'] ?? method['name_en'] ?? ''
                  : '';
            })
            .where((name) => name.isNotEmpty)
            .toList();

        return product;
      }).toList();
    } catch (e) {
      print('Error fetching products: $e');
      return [];
    }
  }

  Future<List<Map<String, dynamic>>> getProductVariants(
    String productId,
  ) async {
    try {
      final res = await client
          .from('product_variants')
          .select()
          .eq('product_id', productId);
      final data = res as List<dynamic>?;
      if (data == null) return [];
      return data.cast<Map<String, dynamic>>();
    } catch (_) {
      return [];
    }
  }

  // Cart Methods

  Future<Map<String, dynamic>?> getCart(String userId) async {
    try {
      final res = await client
          .from('carts')
          .select('''
            *,
            cart_items (
              *,
              products (
                *,
                product_images (*)
              ),
              product_variants (*),
              cutting_methods (*)
            )
          ''')
          .eq('user_id', userId)
          .maybeSingle();

      return res;
    } catch (e) {
      print('Error fetching cart: $e');
      return null;
    }
  }

  Future<void> addToCart({
    required String userId,
    required String productId,
    String? variantId,
    required int qty,
    int? cuttingMethodId,
  }) async {
    try {
      // 1. Get or create cart
      var cart = await getCart(userId);
      String cartId;

      if (cart == null) {
        final newCart = await client
            .from('carts')
            .insert({'user_id': userId})
            .select()
            .single();
        cartId = newCart['id'];
      } else {
        cartId = cart['id'];
      }

      // 2. Check if item exists
      var query = client
          .from('cart_items')
          .select()
          .eq('cart_id', cartId)
          .eq('product_id', productId);

      if (variantId != null) {
        query = query.eq('variant_id', variantId);
      } else {
        query = query.is_('variant_id', null);
      }

      if (cuttingMethodId != null) {
        query = query.eq('cutting_method_id', cuttingMethodId);
      } else {
        query = query.is_('cutting_method_id', null);
      }

      final existingItems = await query;

      if (existingItems != null && existingItems.isNotEmpty) {
        // Update quantity
        final item = existingItems.first;
        final newQty = item['qty'] + qty;
        await client
            .from('cart_items')
            .update({'qty': newQty})
            .eq('id', item['id']);
      } else {
        // Insert new item
        await client.from('cart_items').insert({
          'cart_id': cartId,
          'product_id': productId,
          'variant_id': variantId,
          'qty': qty,
          'cutting_method_id': cuttingMethodId,
        });
      }
    } catch (e) {
      print('Error adding to cart: $e');
      rethrow;
    }
  }

  Future<void> updateCartItemQuantity(String itemId, int qty) async {
    try {
      if (qty <= 0) {
        await client.from('cart_items').delete().eq('id', itemId);
      } else {
        await client.from('cart_items').update({'qty': qty}).eq('id', itemId);
      }
    } catch (e) {
      print('Error updating cart item: $e');
      rethrow;
    }
  }

  Future<void> removeCartItem(String itemId) async {
    try {
      await client.from('cart_items').delete().eq('id', itemId);
    } catch (e) {
      print('Error removing cart item: $e');
      rethrow;
    }
  }

  Future<void> clearCart(String cartId) async {
    try {
      await client.from('cart_items').delete().eq('cart_id', cartId);
    } catch (e) {
      print('Error clearing cart: $e');
      rethrow;
    }
  }
}
